defmodule Memex.MixProject do
  use Mix.Project

  def project do
    [
      app: :memex,
      version: "0.1.15",
      elixir: "1.15.6",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      dialyzer: [plt_add_apps: [:ex_unit]],
      consolidate_protocols: Mix.env() not in [:dev, :test],
      preferred_cli_env: ["test.all": :test],
      # ExDoc
      name: "memEx",
      source_url: "https://gitea.bubbletea.dev/shibao/memEx",
      homepage_url: "https://gitea.bubbletea.dev/shibao/memEx",
      docs: [
        # The main page in the docs
        main: "README.md",
        # logo: "path/to/logo.png",
        extras: ["README.md"]
      ],
      authors: ["shibao"]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Memex.Application, []},
      extra_applications: [:logger, :runtime_tools, :os_mon, :crypto]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:bcrypt_elixir, "~> 3.0"},
      {:phoenix, "~> 1.7.0"},
      {:phoenix_ecto, "~> 4.4"},
      {:phoenix_html, "~> 3.0"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.20.0"},
      {:phoenix_live_dashboard, "~> 0.8"},
      {:ecto_sql, "~> 3.6"},
      {:postgrex, ">= 0.0.0"},
      {:floki, ">= 0.30.0", only: :test},
      # {:esbuild, "~> 0.3", runtime: Mix.env() == :dev},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:swoosh, "~> 1.6"},
      {:gen_smtp, "~> 1.0"},
      {:oban, "~> 2.10"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.18"},
      {:jason, "~> 1.2"},
      {:plug_cowboy, "~> 2.5"},
      {:ecto_psql_extras, "~> 0.6"},
      {:eqrcode, "~> 0.1.10"},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "compile", "ecto.setup", "cmd npm install --prefix assets"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "format.all": [
        "cmd npm run format --prefix assets",
        "format",
        "gettext.extract --merge",
        "gettext.merge --no-fuzzy priv/gettext"
      ],
      "test.all": [
        "cmd npm run test --prefix assets",
        "dialyzer",
        "credo --strict",
        "format --check-formatted",
        "gettext.extract --check-up-to-date",
        "ecto.drop --quiet",
        "ecto.create --quiet",
        "ecto.migrate --quiet",
        "test"
      ]
    ]
  end
end
