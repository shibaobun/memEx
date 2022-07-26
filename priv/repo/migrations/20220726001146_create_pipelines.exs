defmodule Memex.Repo.Migrations.CreatePipelines do
  use Ecto.Migration

  def change do
    create table(:pipelines, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string
      add :description, :text
      add :visibility, :string

      timestamps()
    end
  end
end
