defmodule Memex.Contexts.Context do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "contexts" do
    field :content, :string
    field :tag, {:array, :string}
    field :title, :string
    field :visibility, Ecto.Enum, values: [:public, :private, :unlisted]

    timestamps()
  end

  @doc false
  def changeset(context, attrs) do
    context
    |> cast(attrs, [:title, :content, :tag, :visibility])
    |> validate_required([:title, :content, :tag, :visibility])
  end
end
