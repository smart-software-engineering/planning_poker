defmodule PlanningPoker.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PlanningPokerWeb.Telemetry,
      PlanningPoker.Repo,
      {DNSCluster, query: Application.get_env(:planning_poker, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: PlanningPoker.PubSub},
      PlanningPokerWeb.Presence,
      # Registry for tracking processes
      {Registry, keys: :unique, name: PlanningPoker.Registry},
      # Game management
      {PlanningPoker.Voting.VotingSupervisor, []},
      {PlanningPoker.UserTracking.UserTrackingSupervisor, []},
      # Cleanup scheduler for data privacy compliance
      PlanningPoker.Poker.CleanupScheduler,
      # Start a worker by calling: PlanningPoker.Worker.start_link(arg)
      # {PlanningPoker.Worker, arg},
      # Start to serve requests, typically the last entry
      PlanningPokerWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PlanningPoker.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PlanningPokerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
