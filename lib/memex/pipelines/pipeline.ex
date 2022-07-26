defmodule Memex.Pipelines.Pipeline do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "pipelines" do
    field :description, :string
    field :title, :string
    field :visibility, Ecto.Enum, values: [:public, :private, :unlisted]

    timestamps()
  end

  @doc false
  def changeset(pipeline, attrs) do
    pipeline
    |> cast(attrs, [:title, :description, :visibility])
    |> validate_required([:title, :description, :visibility])
  end
end
