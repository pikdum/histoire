defmodule Histoire.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      HistoireWeb.Telemetry,
      Histoire.Repo,
      Histoire.Nyaa.RateLimiter,
      Histoire.SubsPlease.RateLimiter,
      Histoire.TVDB.RateLimiter,
      Histoire.TVDB.TokenStore,
      {DNSCluster, query: Application.get_env(:histoire, :dns_cluster_query) || :ignore},
      {Oban,
       AshOban.config(
         Application.fetch_env!(:histoire, :ash_domains),
         Application.fetch_env!(:histoire, Oban)
       )},
      {Phoenix.PubSub, name: Histoire.PubSub},
      # Start a worker by calling: Histoire.Worker.start_link(arg)
      # {Histoire.Worker, arg},
      # Start to serve requests, typically the last entry
      HistoireWeb.Endpoint
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Histoire.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    HistoireWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
