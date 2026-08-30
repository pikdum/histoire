defmodule AnimeDataWeb.Plugs.AdminAuth do
  @moduledoc false

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    username = System.get_env("ADMIN_USERNAME")
    password = System.get_env("ADMIN_PASSWORD")

    cond do
      present?(username) and present?(password) ->
        Plug.BasicAuth.basic_auth(conn, username: username, password: password)

      Application.get_env(:anime_data, :dev_routes, false) ->
        conn

      true ->
        conn
        |> send_resp(:not_found, "Not Found")
        |> halt()
    end
  end

  defp present?(value), do: is_binary(value) and value != ""
end
