defmodule Memex.Repo.Migrations.CreateNotes do
  use Ecto.Migration

  def up do
    create table(:notes, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string
      add :content, :text
      add :tags, {:array, :citext}
      add :visibility, :string

      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id)

      timestamps()
    end

    flush()

    execute """
    CREATE FUNCTION immutable_array_to_string(text[], text)
      RETURNS text LANGUAGE sql IMMUTABLE as $$SELECT array_to_string($1, $2)$$
    """

    execute """
    ALTER TABLE notes
      ADD COLUMN search tsvector
      GENERATED ALWAYS AS (
        setweight(to_tsvector('english', coalesce(title, '')), 'A') ||
        setweight(to_tsvector('english', coalesce(immutable_array_to_string(tags, ' '), '')), 'B') ||
        setweight(to_tsvector('english', coalesce(content, '')), 'C')
      ) STORED
    """

    execute("CREATE INDEX notes_trgm_idx ON notes USING GIN (search)")
  end

  def down do
    drop table(:notes)
    execute("DROP FUNCTION immutable_array_to_string(text[], text)")
  end
end
