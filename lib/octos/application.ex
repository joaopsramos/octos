defmodule Octos.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      OctosWeb.Telemetry,
      Octos.Repo,
      {DNSCluster, query: Application.get_env(:octos, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Octos.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Octos.Finch},
      # Start a worker by calling: Octos.Worker.start_link(arg)
      # {Octos.Worker, arg},
      # Start to serve requests, typically the last entry
      OctosWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Octos.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    OctosWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
