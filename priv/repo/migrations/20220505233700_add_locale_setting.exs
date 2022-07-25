defmodule Memex.Repo.Migrations.AddLocaleSetting do
  use Ecto.Migration

  def change do
    alter table("users") do
      add :locale, :string
    end
  end
end
