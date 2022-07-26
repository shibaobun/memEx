defmodule Memex.Repo.Migrations.CreateContextNotes do
  use Ecto.Migration

  def change do
    create table(:context_notes, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :context_id, references(:contexts, on_delete: :nothing, type: :binary_id)
      add :note_id, references(:notes, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create index(:context_notes, [:context_id])
    create index(:context_notes, [:note_id])
  end
end
