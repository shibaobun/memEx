defmodule Memex.Repo.Migrations.CreateContexts do
  use Ecto.Migration

  def change do
    create table(:contexts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string
      add :content, :text
      add :tags, {:array, :string}
      add :visibility, :string

      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id)

      timestamps()
    end

    flush()

    execute """
    ALTER TABLE contexts
      ADD COLUMN search tsvector
      GENERATED ALWAYS AS (
        setweight(to_tsvector('english', coalesce(title, '')), 'A') ||
        setweight(to_tsvector('english', coalesce(immutable_array_to_string(tags, ' '), '')), 'B') ||
        setweight(to_tsvector('english', coalesce(content, '')), 'C')
      ) STORED
    """

    execute("CREATE INDEX contexts_trgm_idx ON contexts USING GIN (search)")
  end

  def down do
    drop table(:contexts)
  end
end
