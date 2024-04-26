defmodule Sorgenfri.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    Logger.add_handlers(:sorgenfri)
    :ok = Oban.Telemetry.attach_default_logger()

    children = [
      # Start the Telemetry supervisor
      SorgenfriWeb.Telemetry,
      # Start the Ecto repository
      Sorgenfri.Repo,
      # Start Oban
      {Oban, Application.fetch_env!(:sorgenfri, Oban)},
      # Start the PubSub system
      {Phoenix.PubSub, name: Sorgenfri.PubSub},
      # Start Finch
      {Finch, name: Sorgenfri.Finch},
      # Start the Endpoint (http/https)
      SorgenfriWeb.Endpoint,
      # Start a worker by calling: Sorgenfri.Worker.start_link(arg)
      # {Sorgenfri.Worker, arg}

      # Notify systemd that we are ready
      :systemd.ready()
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Sorgenfri.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SorgenfriWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
