defmodule Memex.Repo.Migrations.UseSlugs do
  use Ecto.Migration

  def change do
    rename table(:notes), :title, to: :slug
    create unique_index(:notes, [:slug])

    rename table(:contexts), :title, to: :slug
    create unique_index(:contexts, [:slug])

    rename table(:pipelines), :title, to: :slug
    create unique_index(:pipelines, [:slug])
  end
end
