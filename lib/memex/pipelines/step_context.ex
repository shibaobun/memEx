defmodule Memex.Pipelines.StepContext do
  @moduledoc """
  Represents a has-many relation between a step and related contexts
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.{Changeset, UUID}
  alias Memex.{Contexts.Context, Pipelines.Step}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "step_contexts" do
    belongs_to :step, Step
    belongs_to :context, Context

    timestamps()
  end

  @type t :: %__MODULE__{
          step: Step.t() | Ecto.Association.NotLoaded.t(),
          step_id: Step.id(),
          context: Context.t() | Ecto.Association.NotLoaded.t(),
          context_id: Context.id(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }
  @type id :: UUID.t()
  @type changeset :: Changeset.t(t())

  @doc false
  @spec create_changeset(Step.t(), Context.t()) :: changeset()
  def create_changeset(
        %Step{id: step_id, user_id: user_id},
        %Context{id: context_id, user_id: user_id}
      ) do
    %__MODULE__{}
    |> change(step_id: step_id, context_id: context_id)
    |> validate_required([:step_id, :context_id])
  end
end
