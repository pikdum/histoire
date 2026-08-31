defmodule HistoireWeb.HealthControllerTest do
  use HistoireWeb.ConnCase, async: true

  test "GET /health checks database connectivity", %{conn: conn} do
    assert %{"status" => "ok"} = conn |> get(~p"/health") |> json_response(200)
  end
end
