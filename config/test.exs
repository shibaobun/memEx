import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :lokal, Lokal.Repo,
  url:
    System.get_env("TEST_DATABASE_URL") ||
      "ecto://postgres:postgres@localhost/lokal_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :lokal, LokalWeb.Endpoint,
  http: [ip: {0, 0, 0, 0}, port: 4002],
  secret_key_base: "T4DkRImgeMNCcPcTWBCZyKYp3KQ8yyPD33VT4wj6ogbP8fIGUsqmOTNX3clTMrLo",
  server: false

# In test we don't send emails.
config :lokal, Lokal.Mailer, adapter: Swoosh.Adapters.Test

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
