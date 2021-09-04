defmodule Lokal.Repo.Migrator do
  use GenServer
  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], [])
  end

  def init(_) do
    migrate!()
    {:ok, nil}
  end

  def migrate! do
    path = Application.app_dir(:lokal, "priv/repo/migrations")
    Ecto.Migrator.run(Lokal.Repo, path, :up, all: true)
  end
end
