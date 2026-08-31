defmodule Histoire.AI.Config do
  @moduledoc false

  def model do
    model = Application.get_env(:histoire, :matching_model, "openai_codex:gpt-5.6-luna")

    case Application.get_env(:histoire, :matching_base_url) do
      base_url when is_binary(base_url) ->
        ReqLLM.model!(%{provider: :openai, id: model, base_url: base_url})

      _base_url ->
        model
    end
  end

  def req_llm_opts do
    cond do
      Application.get_env(:histoire, :matching_base_url) ->
        [api_key: Application.fetch_env!(:histoire, :matching_api_key)]

      oauth_file = Application.get_env(:req_llm, :oauth_file) ->
        [provider_options: [auth_mode: :oauth, oauth_file: oauth_file]]

      credentials = native_codex_credentials() ->
        [
          provider_options: [
            auth_mode: :oauth,
            access_token: credentials.access_token,
            chatgpt_account_id: credentials.account_id
          ]
        ]

      true ->
        []
    end
  end

  defp native_codex_credentials do
    path = Application.get_env(:histoire, :codex_auth_file)

    with path when is_binary(path) <- path,
         {:ok, contents} <- File.read(path),
         {:ok, %{"tokens" => tokens}} <- Jason.decode(contents),
         access_token when is_binary(access_token) <- tokens["access_token"],
         account_id when is_binary(account_id) <- tokens["account_id"] do
      %{access_token: access_token, account_id: account_id}
    else
      _other -> nil
    end
  end
end
