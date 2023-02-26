defmodule Memex.Repo.Migrations.CreateInvites do
  use Ecto.Migration

  def change do
    create table(:invites, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :token, :string
      add :uses_left, :integer, default: nil
      add :disabled_at, :naive_datetime, default: nil

      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id)

      timestamps()
    end

    create index(:invites, [:user_id])
  end
end
