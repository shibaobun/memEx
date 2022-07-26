defmodule Memex.Repo.Migrations.CreateContexts do
  use Ecto.Migration

  def change do
    create table(:contexts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string
      add :content, :text
      add :tag, {:array, :string}
      add :visibility, :string

      timestamps()
    end
  end
end
