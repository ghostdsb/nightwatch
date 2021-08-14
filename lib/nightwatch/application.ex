defmodule Nightwatch.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      NightwatchWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Nightwatch.PubSub},
      # Start the Endpoint (http/https)
      NightwatchWeb.Endpoint,
      # Start a worker by calling: Nightwatch.Worker.start_link(arg)
      {Registry, keys: :unique, name: Nightwatch.GameRegistry},
      {Nightwatch.Game.World, []},
      {DynamicSupervisor, strategy: :one_for_one, name: Nightwatch.GameSupervisor}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Nightwatch.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    NightwatchWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
