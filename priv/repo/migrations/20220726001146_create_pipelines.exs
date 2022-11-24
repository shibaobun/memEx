defmodule Memex.Repo.Migrations.CreatePipelines do
  use Ecto.Migration

  def change do
    create table(:pipelines, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string
      add :description, :text
      add :tags, {:array, :citext}
      add :visibility, :string

      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id)

      timestamps()
    end

    flush()

    execute """
    ALTER TABLE pipelines
      ADD COLUMN search tsvector
      GENERATED ALWAYS AS (
        setweight(to_tsvector('english', coalesce(title, '')), 'A') ||
        setweight(to_tsvector('english', coalesce(immutable_array_to_string(tags, ' '), '')), 'B') ||
        setweight(to_tsvector('english', coalesce(description, '')), 'C')
      ) STORED
    """

    execute("CREATE INDEX pipelines_trgm_idx ON pipelines USING GIN (search)")
  end

  def down do
    drop table(:pipelines)
  end
end
