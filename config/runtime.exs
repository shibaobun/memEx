import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# Start the phoenix server if environment is set and running in a release
if System.get_env("PHX_SERVER") && System.get_env("RELEASE_NAME") do
  config :lokal, LokalWeb.Endpoint, server: true
end

# Set default locale
config :gettext, :default_locale, System.get_env("LOCALE", "en_US")

maybe_ipv6 = if System.get_env("ECTO_IPV6") == "true", do: [:inet6], else: []

database_url =
  if config_env() == :test do
    System.get_env(
      "TEST_DATABASE_URL",
      "ecto://postgres:postgres@localhost/lokal_test#{System.get_env("MIX_TEST_PARTITION")}"
    )
  else
    System.get_env("DATABASE_URL", "ecto://postgres:postgres@lokal-db/lokal")
  end

host =
  System.get_env("HOST") ||
    raise "No hostname set! Must be the domain and tld like `lokal.bubbletea.dev`."

interface =
  if config_env() in [:dev, :test],
    do: {0, 0, 0, 0},
    else: {0, 0, 0, 0, 0, 0, 0, 0}

config :lokal, Lokal.Repo,
  # ssl: true,
  url: database_url,
  pool_size: String.to_integer(System.get_env("POOL_SIZE", "10")),
  socket_options: maybe_ipv6

config :lokal, LokalWeb.Endpoint,
  url: [scheme: "https", host: host, port: 443],
  http: [
    # See the documentation on https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html
    # for details about using IPv6 vs IPv4 and loopback vs public addresses.
    ip: interface,
    port: String.to_integer(System.get_env("PORT", "4000"))
  ],
  server: true,
  registration: System.get_env("REGISTRATION", "invite")

if config_env() == :prod do
  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  config :lokal, LokalWeb.Endpoint, secret_key_base: secret_key_base

  # Automatically apply migrations
  config :lokal, Lokal.Application, automigrate: true

  # Set up SMTP settings
  config :lokal, Lokal.Mailer,
    adapter: Swoosh.Adapters.SMTP,
    relay: System.get_env("SMTP_HOST") || raise("No SMTP_HOST set!"),
    port: System.get_env("SMTP_PORT", "587"),
    username: System.get_env("SMTP_USERNAME") || raise("No SMTP_USERNAME set!"),
    password: System.get_env("SMTP_PASSWORD") || raise("No SMTP_PASSWORD set!"),
    ssl: System.get_env("SMTP_SSL") == "true",
    email_from: System.get_env("EMAIL_FROM", "no-reply@#{System.get_env("HOST")}"),
    email_name: System.get_env("EMAIL_NAME", "Lokal")

  # ## Using releases
  #
  # If you are doing OTP releases, you need to instruct Phoenix
  # to start each relevant endpoint:
  #
  #     config :lokal, LokalWeb.Endpoint, server: true
  #
  # Then you can assemble a release by calling `mix release`.
  # See `mix help release` for more information.
end
