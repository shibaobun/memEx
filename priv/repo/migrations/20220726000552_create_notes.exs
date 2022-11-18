defmodule Memex.Repo.Migrations.CreateNotes do
  use Ecto.Migration

  def change do
    create table(:notes, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string
      add :content, :text
      add :tags, {:array, :string}
      add :visibility, :string

      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id)

      timestamps()
    end
  end
end
