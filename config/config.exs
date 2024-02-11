# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :sorgenfri,
  ecto_repos: [Sorgenfri.Repo]

# Configure the repo
config :sorgenfri, Sorgenfri.Repo, migration_timestamps: [type: :timestamptz]

# Configures the endpoint
config :sorgenfri, SorgenfriWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: SorgenfriWeb.ErrorHTML, json: SorgenfriWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Sorgenfri.PubSub,
  live_view: [signing_salt: "mG2ufvdt"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :sorgenfri, Sorgenfri.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.20.0",
  path: System.get_env("MIX_ESBUILD_PATH"),
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{
      "NODE_PATH" => System.get_env("MIX_ESBUILD_NODE_PATH") || Path.expand("../deps", __DIR__)
    }
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.1",
  path: System.get_env("MIX_TAILWIND_PATH"),
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
