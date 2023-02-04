defmodule Lokal.Repo.Migrations.RecordInvites do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :invite_id, references(:invites, type: :binary_id)
    end

    rename table(:invites), :user_id, to: :created_by_id
  end
end
