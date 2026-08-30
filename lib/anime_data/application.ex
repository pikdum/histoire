defmodule AnimeData.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      AnimeDataWeb.Telemetry,
      AnimeData.Repo,
      AnimeData.SubsPlease.RateLimiter,
      AnimeData.TVDB.RateLimiter,
      AnimeData.TVDB.TokenStore,
      {DNSCluster, query: Application.get_env(:anime_data, :dns_cluster_query) || :ignore},
      {Oban,
       AshOban.config(
         Application.fetch_env!(:anime_data, :ash_domains),
         Application.fetch_env!(:anime_data, Oban)
       )},
      {Phoenix.PubSub, name: AnimeData.PubSub},
      # Start a worker by calling: AnimeData.Worker.start_link(arg)
      # {AnimeData.Worker, arg},
      # Start to serve requests, typically the last entry
      AnimeDataWeb.Endpoint,
      {Absinthe.Subscription, AnimeDataWeb.Endpoint},
      AshGraphql.Subscription.Batcher
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AnimeData.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AnimeDataWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
