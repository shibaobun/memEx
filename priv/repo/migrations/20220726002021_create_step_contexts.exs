defmodule Memex.Repo.Migrations.CreateStepContexts do
  use Ecto.Migration

  def change do
    create table(:step_contexts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :step_id, references(:steps, on_delete: :nothing, type: :binary_id)
      add :context_id, references(:contexts, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create index(:step_contexts, [:step_id])
    create index(:step_contexts, [:context_id])
  end
end
