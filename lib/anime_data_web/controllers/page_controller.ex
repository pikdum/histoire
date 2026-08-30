defmodule AnimeDataWeb.PageController do
  use AnimeDataWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
