defmodule HistoireWeb.Router do
  use HistoireWeb, :router

  import Oban.Web.Router
  import AshAdmin.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {HistoireWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :admin_auth do
    plug HistoireWeb.Plugs.AdminAuth
  end

  scope "/", HistoireWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  scope "/", HistoireWeb do
    pipe_through :api

    get "/health", HealthController, :index
  end

  scope "/api/v1", HistoireWeb.Api do
    pipe_through :api

    get "/shows", ShowController, :index
    get "/shows/:id", ShowController, :show
    get "/schedule", ScheduleController, :index
    get "/downloads/:id/files", DownloadController, :files
  end

  scope "/" do
    pipe_through [:browser, :admin_auth]

    oban_dashboard("/oban")
  end

  scope "/admin" do
    pipe_through [:browser, :admin_auth]

    ash_admin "/"
  end

  # Other scopes may use custom stacks.
  # scope "/api", HistoireWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:histoire, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: HistoireWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
