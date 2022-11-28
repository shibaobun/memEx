defmodule Memex.Repo.Migrations.FixSearch do
  use Ecto.Migration

  def up do
    reset_search_columns()
  end

  def down do
    # no way to rollback this migration since the previous generated search columns were invalid
    reset_search_columns()
  end

  defp reset_search_columns() do
    alter table(:notes), do: remove(:search)
    alter table(:contexts), do: remove(:search)
    alter table(:pipelines), do: remove(:search)

    flush()

    execute """
    ALTER TABLE notes
    ADD COLUMN search tsvector
      GENERATED ALWAYS AS (
        setweight(to_tsvector('english', coalesce(slug, '')), 'A') ||
        setweight(to_tsvector('english', coalesce(immutable_array_to_string(tags, ' '), '')), 'B') ||
        setweight(to_tsvector('english', coalesce(content, '')), 'C')
      ) STORED
    """

    execute("CREATE INDEX notes_trgm_idx ON notes USING GIN (search)")

    execute """
    ALTER TABLE contexts
      ADD COLUMN search tsvector
      GENERATED ALWAYS AS (
        setweight(to_tsvector('english', coalesce(slug, '')), 'A') ||
        setweight(to_tsvector('english', coalesce(immutable_array_to_string(tags, ' '), '')), 'B') ||
        setweight(to_tsvector('english', coalesce(content, '')), 'C')
      ) STORED
    """

    execute("CREATE INDEX contexts_trgm_idx ON contexts USING GIN (search)")

    execute """
    ALTER TABLE pipelines
      ADD COLUMN search tsvector
      GENERATED ALWAYS AS (
        setweight(to_tsvector('english', coalesce(slug, '')), 'A') ||
        setweight(to_tsvector('english', coalesce(immutable_array_to_string(tags, ' '), '')), 'B') ||
        setweight(to_tsvector('english', coalesce(description, '')), 'C')
      ) STORED
    """

    execute("CREATE INDEX pipelines_trgm_idx ON pipelines USING GIN (search)")
  end
end
