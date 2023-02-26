defmodule Memex.Repo.Migrator do
  @moduledoc """
  Genserver to automatically perform all migration on app start
  """

  use GenServer
  require Logger

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], [])
  end

  def init(_opts) do
    {:ok, if(automigrate_enabled?(), do: migrate!())}
  end

  def migrate! do
    path = Application.app_dir(:memex, "priv/repo/migrations")
    Ecto.Migrator.run(Memex.Repo, path, :up, all: true)
  end

  defp automigrate_enabled? do
    Application.get_env(:memex, Memex.Application, automigrate: false)[:automigrate]
  end
end
