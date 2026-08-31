defmodule HistoireWeb.Api.ShowController do
  use HistoireWeb, :controller

  alias Histoire.Catalog.ReadModel

  require Logger

  def index(conn, params) do
    case ReadModel.list_shows(params["q"]) do
      {:ok, shows} -> json(conn, %{data: shows})
      {:error, reason} -> render_error(conn, :internal_server_error, reason)
    end
  end

  def show(conn, %{"id" => id}) do
    with {id, ""} <- Integer.parse(id),
         {:ok, show} <- ReadModel.get_show(id) do
      json(conn, %{data: show})
    else
      :error -> render_error(conn, :bad_request, :invalid_id)
      {:error, %Ash.Error.Query.NotFound{}} -> render_error(conn, :not_found, :show_not_found)
      {:error, :invalid_id} -> render_error(conn, :bad_request, :invalid_id)
      {:error, reason} -> render_error(conn, :internal_server_error, reason)
    end
  end

  defp render_error(conn, status, reason) do
    if status == :internal_server_error do
      Logger.error("show API failed: #{inspect(reason)}")
    end

    message =
      if status == :internal_server_error, do: "internal server error", else: to_string(reason)

    conn
    |> put_status(status)
    |> json(%{error: message})
  end
end
