defmodule Memex.Steps.StepContext do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "step_contexts" do

    field :step_id, :binary_id
    field :context_id, :binary_id

    timestamps()
  end

  @doc false
  def changeset(step_context, attrs) do
    step_context
    |> cast(attrs, [])
    |> validate_required([])
  end
end
