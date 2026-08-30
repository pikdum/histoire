defmodule AnimeDataWeb.HealthController do
  use AnimeDataWeb, :controller

  def index(conn, _params) do
    case Ecto.Adapters.SQL.query(AnimeData.Repo, "SELECT 1", [], timeout: 2_000) do
      {:ok, _result} -> json(conn, %{status: "ok"})
      {:error, _error} -> conn |> put_status(:service_unavailable) |> json(%{status: "error"})
    end
  end
end
