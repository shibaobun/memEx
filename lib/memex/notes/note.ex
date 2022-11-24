defmodule Memex.Notes.Note do
  @moduledoc """
  Schema for a user-written note
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.{Changeset, UUID}
  alias Memex.Accounts.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "notes" do
    field :title, :string
    field :content, :string
    field :tags, {:array, :string}
    field :tags_string, :string, virtual: true
    field :visibility, Ecto.Enum, values: [:public, :private, :unlisted]

    belongs_to :user, User

    timestamps()
  end

  @type t :: %__MODULE__{
          title: String.t(),
          content: String.t(),
          tags: [String.t()] | nil,
          tags_string: String.t(),
          visibility: :public | :private | :unlisted,
          user: User.t() | Ecto.Association.NotLoaded.t(),
          user_id: User.id(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }
  @type id :: UUID.t()
  @type changeset :: Changeset.t(t())

  @doc false
  @spec create_changeset(attrs :: map(), User.t()) :: changeset()
  def create_changeset(attrs, %User{id: user_id}) do
    %__MODULE__{}
    |> cast(attrs, [:title, :content, :tags, :visibility])
    |> change(user_id: user_id)
    |> cast_tags_string(attrs)
    |> validate_required([:title, :content, :user_id, :visibility])
  end

  @spec update_changeset(t(), attrs :: map(), User.t()) :: changeset()
  def update_changeset(%{user_id: user_id} = note, attrs, %User{id: user_id}) do
    note
    |> cast(attrs, [:title, :content, :tags, :visibility])
    |> cast_tags_string(attrs)
    |> validate_required([:title, :content, :visibility])
  end

  defp cast_tags_string(changeset, %{"tags_string" => tags_string})
       when tags_string |> is_binary() do
    tags =
      tags_string
      |> String.split(",", trim: true)
      |> Enum.map(fn str -> str |> String.trim() end)
      |> Enum.sort()

    changeset |> change(tags: tags)
  end

  defp cast_tags_string(changeset, _attrs), do: changeset
end
