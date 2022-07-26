defmodule Memex.Repo.Migrations.CreateSteps do
  use Ecto.Migration

  def change do
    create table(:steps, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string
      add :description, :text
      add :position, :integer
      add :pipeline_id, references(:pipelines, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create index(:steps, [:pipeline_id])
  end
end
