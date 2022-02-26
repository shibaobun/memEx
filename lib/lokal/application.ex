defmodule Lokal.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Lokal.Repo,
      # Start the Telemetry supervisor
      LokalWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Lokal.PubSub},
      # Start the Endpoint (http/https)
      LokalWeb.Endpoint,
      # Add Oban
      {Oban, oban_config()}
      # Start a worker by calling: Lokal.Worker.start_link(arg)
      # {Lokal.Worker, arg}
    ]

    # Automatically migrate on start in prod
    children =
      if Application.get_env(:lokal, Lokal.Application, automigrate: false)[:automigrate],
        do: children ++ [Lokal.Repo.Migrator],
        else: children

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Lokal.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LokalWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp oban_config do
    Application.fetch_env!(:lokal, Oban)
  end
end
