# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :lokal,
  ecto_repos: [Lokal.Repo],
  generators: [binary_id: true]

config :lokal, Lokal.Accounts, registration: System.get_env("REGISTRATION", "invite")

# Configures the endpoint
config :lokal, LokalWeb.Endpoint,
  url: [scheme: "https", host: System.get_env("HOST") || "localhost", port: "443"],
  http: [port: String.to_integer(System.get_env("PORT") || "4000")],
  secret_key_base: "KH59P0iZixX5gP/u+zkxxG8vAAj6vgt0YqnwEB5JP5K+E567SsqkCz69uWShjE7I",
  render_errors: [view: LokalWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Lokal.PubSub,
  live_view: [signing_salt: "zOLgd3lr"]

config :lokal, Lokal.Application, automigrate: false

config :lokal, :generators,
  migration: true,
  binary_id: true,
  sample_binary_id: "11111111-1111-1111-1111-111111111111"

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :lokal, Lokal.Mailer, adapter: Swoosh.Adapters.Local

# Swoosh API client is needed for adapters other than SMTP.
config :swoosh, :api_client, false

# Gettext
config :gettext, :default_locale, "en_US"

# Configure Oban
config :lokal, Oban,
  repo: Lokal.Repo,
  plugins: [Oban.Plugins.Pruner],
  queues: [default: 10, mailers: 20]

# Configure esbuild (the version is required)
# config :esbuild,
#   version: "0.14.0",
#   default: [
#     args:
#       ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
#     cd: Path.expand("../assets", __DIR__),
#     env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
#   ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
