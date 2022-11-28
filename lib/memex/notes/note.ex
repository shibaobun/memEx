defmodule Memex.Notes.Note do
  @moduledoc """
  Schema for a user-written note
  """
  use Ecto.Schema
  import Ecto.Changeset
  import MemexWeb.Gettext
  alias Ecto.{Changeset, UUID}
  alias Memex.{Accounts.User, Repo}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "notes" do
    field :slug, :string
    field :content, :string
    field :tags, {:array, :string}
    field :tags_string, :string, virtual: true
    field :visibility, Ecto.Enum, values: [:public, :private, :unlisted]

    belongs_to :user, User

    timestamps()
  end

  @type t :: %__MODULE__{
          slug: slug(),
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
  @type slug :: String.t()
  @type changeset :: Changeset.t(t())

  @doc false
  @spec create_changeset(attrs :: map(), User.t()) :: changeset()
  def create_changeset(attrs, %User{id: user_id}) do
    %__MODULE__{}
    |> cast(attrs, [:slug, :content, :tags, :visibility])
    |> change(user_id: user_id)
    |> cast_tags_string(attrs)
    |> validate_format(:slug, ~r/^[\p{L}\p{N}\-]+$/,
      message: dgettext("errors", "invalid format: only numbers, letters and hyphen are accepted")
    )
    |> validate_required([:slug, :content, :user_id, :visibility])
    |> unique_constraint(:slug)
    |> unsafe_validate_unique(:slug, Repo)
  end

  @spec update_changeset(t(), attrs :: map(), User.t()) :: changeset()
  def update_changeset(%{user_id: user_id} = note, attrs, %User{id: user_id}) do
    note
    |> cast(attrs, [:slug, :content, :tags, :visibility])
    |> cast_tags_string(attrs)
    |> validate_format(:slug, ~r/^[\p{L}\p{N}\-]+$/,
      message: dgettext("errors", "invalid format: only numbers, letters and hyphen are accepted")
    )
    |> validate_required([:slug, :content, :visibility])
    |> unique_constraint(:slug)
    |> unsafe_validate_unique(:slug, Repo)
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
