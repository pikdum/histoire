defmodule HistoireWeb.Api.ScheduleController do
  use HistoireWeb, :controller

  alias Histoire.Catalog.ReadModel

  require Logger

  def index(conn, _params) do
    case ReadModel.schedule() do
      {:ok, entries} ->
        json(conn, %{data: entries})

      {:error, reason} ->
        Logger.error("schedule API failed: #{inspect(reason)}")
        conn |> put_status(:internal_server_error) |> json(%{error: "internal server error"})
    end
  end
end
