defmodule Memex.Contexts.ContextNote do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "context_notes" do
    field :context_id, :binary_id
    field :note_id, :binary_id

    timestamps()
  end

  @doc false
  def changeset(context_note, attrs) do
    context_note
    |> cast(attrs, [])
    |> validate_required([])
  end
end
