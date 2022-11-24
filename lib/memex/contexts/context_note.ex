defmodule Memex.Contexts.ContextNote do
  @moduledoc """
  Represents a mapping of a note to a context
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Memex.{Contexts.Context, Contexts.ContextNote, Notes.Note}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "context_notes" do
    belongs_to :context, Context
    belongs_to :note, Note

    timestamps()
  end

  @type t :: %ContextNote{
          context: Context.t() | nil,
          context_id: Context.id(),
          note: Note.t(),
          note_id: Note.id(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }
  @type new_context_note :: %ContextNote{}

  @doc false
  def create_changeset(%Context{id: context_id}, %Note{id: note_id}) do
    %ContextNote{}
    |> change(context_id: context_id, note_id: note_id)
    |> validate_required([:context_id, :note_id])
  end
end
