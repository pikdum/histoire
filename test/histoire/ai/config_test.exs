defmodule Histoire.AI.ConfigTest do
  use ExUnit.Case, async: false

  alias Histoire.AI.Config

  test "builds the configured OpenAI-compatible proxy model and options" do
    previous =
      Map.new([:matching_model, :matching_base_url, :matching_api_key], fn key ->
        {key, Application.get_env(:histoire, key)}
      end)

    on_exit(fn ->
      Enum.each(previous, fn {key, value} -> restore_env(:histoire, key, value) end)
    end)

    Application.put_env(:histoire, :matching_model, "openai/gpt-5.6-luna")

    Application.put_env(
      :histoire,
      :matching_base_url,
      "https://ai.snowshoe-bushi.ts.net/v1"
    )

    Application.put_env(:histoire, :matching_api_key, "tailscale")

    assert %LLMDB.Model{
             provider: :openai,
             id: "openai/gpt-5.6-luna",
             base_url: "https://ai.snowshoe-bushi.ts.net/v1"
           } = Config.model()

    assert Config.req_llm_opts() == [api_key: "tailscale"]
  end

  test "adapts the native Codex auth file without logging or copying credentials" do
    path = Path.join(System.tmp_dir!(), "histoire-codex-auth-#{System.unique_integer()}.json")

    File.write!(
      path,
      Jason.encode!(%{
        "tokens" => %{"access_token" => "test-access", "account_id" => "test-account"}
      })
    )

    previous_auth_file = Application.get_env(:histoire, :codex_auth_file)
    previous_base_url = Application.get_env(:histoire, :matching_base_url)

    on_exit(fn ->
      File.rm(path)
      restore_env(:histoire, :codex_auth_file, previous_auth_file)
      restore_env(:histoire, :matching_base_url, previous_base_url)
    end)

    Application.delete_env(:histoire, :matching_base_url)
    Application.put_env(:histoire, :codex_auth_file, path)

    assert Config.req_llm_opts() == [
             provider_options: [
               auth_mode: :oauth,
               access_token: "test-access",
               chatgpt_account_id: "test-account"
             ]
           ]
  end

  defp restore_env(app, key, nil), do: Application.delete_env(app, key)
  defp restore_env(app, key, value), do: Application.put_env(app, key, value)
end
