defmodule Memex.Steps.Step do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "steps" do
    field :description, :string
    field :position, :integer
    field :title, :string
    field :pipeline_id, :binary_id

    timestamps()
  end

  @doc false
  def changeset(step, attrs) do
    step
    |> cast(attrs, [:title, :description, :position])
    |> validate_required([:title, :description, :position])
  end
end
