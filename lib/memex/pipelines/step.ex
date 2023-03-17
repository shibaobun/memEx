defmodule Memex.Pipelines.Steps.Step do
  @moduledoc """
  Represents a step taken while executing a pipeline
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.{Changeset, UUID}
  alias Memex.{Accounts.User, Pipelines.Pipeline}

  @derive {Jason.Encoder,
           only: [
             :title,
             :content,
             :position,
             :inserted_at,
             :updated_at
           ]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "steps" do
    field :title, :string
    field :content, :string
    field :position, :integer

    belongs_to :pipeline, Pipeline
    field :user_id, :binary_id

    timestamps()
  end

  @type t :: %__MODULE__{
          title: String.t(),
          content: String.t(),
          position: non_neg_integer(),
          pipeline: Pipeline.t() | Ecto.Association.NotLoaded.t(),
          pipeline_id: Pipeline.id(),
          user_id: User.id(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }
  @type id :: UUID.t()
  @type changeset :: Changeset.t(t())

  @doc false
  @spec create_changeset(attrs :: map(), position :: non_neg_integer(), Pipeline.t(), User.t()) ::
          changeset()
  def create_changeset(attrs, position, %Pipeline{id: pipeline_id, user_id: user_id}, %User{
        id: user_id
      }) do
    %__MODULE__{}
    |> cast(attrs, [:title, :content])
    |> change(pipeline_id: pipeline_id, user_id: user_id, position: position)
    |> validate_required([:title, :content, :user_id, :position])
  end

  @spec update_changeset(t(), attrs :: map(), User.t()) ::
          changeset()
  def update_changeset(
        %{user_id: user_id} = step,
        attrs,
        %User{id: user_id}
      ) do
    step
    |> cast(attrs, [:title, :content])
    |> validate_required([:title, :content, :user_id, :position])
  end

  @spec position_changeset(t(), position :: non_neg_integer(), User.t()) :: changeset()
  def position_changeset(
        %{user_id: user_id} = step,
        position,
        %User{id: user_id}
      ) do
    step
    |> change(position: position)
    |> validate_required([:title, :content, :user_id, :position])
  end
end
