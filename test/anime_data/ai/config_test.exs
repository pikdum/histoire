defmodule AnimeData.AI.ConfigTest do
  use ExUnit.Case, async: false

  alias AnimeData.AI.Config

  test "adapts the native Codex auth file without logging or copying credentials" do
    path = Path.join(System.tmp_dir!(), "anime-data-codex-auth-#{System.unique_integer()}.json")

    File.write!(
      path,
      Jason.encode!(%{
        "tokens" => %{"access_token" => "test-access", "account_id" => "test-account"}
      })
    )

    previous_auth_file = Application.get_env(:anime_data, :codex_auth_file)
    previous_oauth_file = Application.get_env(:req_llm, :oauth_file)

    on_exit(fn ->
      File.rm(path)
      restore_env(:anime_data, :codex_auth_file, previous_auth_file)
      restore_env(:req_llm, :oauth_file, previous_oauth_file)
    end)

    Application.put_env(:anime_data, :codex_auth_file, path)
    Application.delete_env(:req_llm, :oauth_file)

    assert Config.req_llm_opts() == [
             provider_options: [
               auth_mode: :oauth,
               access_token: "test-access",
               chatgpt_account_id: "test-account"
             ]
           ]
  end

  test "prefers a ReqLLM-managed OAuth file when configured" do
    previous = Application.get_env(:req_llm, :oauth_file)
    on_exit(fn -> restore_env(:req_llm, :oauth_file, previous) end)

    Application.put_env(:req_llm, :oauth_file, "/run/credentials/anime-data-oauth.json")

    assert Config.req_llm_opts() == [
             provider_options: [
               auth_mode: :oauth,
               oauth_file: "/run/credentials/anime-data-oauth.json"
             ]
           ]
  end

  defp restore_env(app, key, nil), do: Application.delete_env(app, key)
  defp restore_env(app, key, value), do: Application.put_env(app, key, value)
end
