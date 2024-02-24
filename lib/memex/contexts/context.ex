defmodule Memex.Contexts.Context do
  @moduledoc """
  Represents a document that synthesizes multiple concepts as defined by notes
  into a single consideration
  """
  use Ecto.Schema
  import Ecto.Changeset
  import MemexWeb.Gettext
  alias Ecto.{Changeset, UUID}
  alias Memex.{Accounts.User, Repo}

  @derive {Phoenix.Param, key: :slug}
  @derive {Jason.Encoder,
           only: [
             :slug,
             :content,
             :tags,
             :visibility,
             :inserted_at,
             :updated_at
           ]}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "contexts" do
    field :slug, :string
    field :content, :string
    field :tags, {:array, :string}
    field :tags_string, :string, virtual: true
    field :visibility, Ecto.Enum, values: [:public, :private, :unlisted]

    field :user_id, :binary_id

    timestamps()
  end

  @type t :: %__MODULE__{
          slug: slug(),
          content: String.t(),
          tags: [String.t()] | nil,
          tags_string: String.t() | nil,
          visibility: :public | :private | :unlisted,
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
    |> validate_required([:slug, :user_id, :visibility])
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
    |> validate_required([:slug, :visibility])
    |> unique_constraint(:slug)
    |> unsafe_validate_unique(:slug, Repo)
  end

  defp cast_tags_string(changeset, attrs) do
    changeset
    |> put_change(:tags_string, changeset |> get_field(:tags) |> get_tags_string())
    |> cast(attrs, [:tags_string])
    |> validate_format(:tags_string, ~r/^[\p{L}\p{N}\-\, ]+$/,
      message:
        dgettext(
          "errors",
          "invalid format: only numbers, letters and hyphen are accepted. tags must be comma or space delimited"
        )
    )
    |> cast_tags()
  end

  defp cast_tags(%{valid?: false} = changeset), do: changeset

  defp cast_tags(%{valid?: true} = changeset) do
    tags = changeset |> get_field(:tags_string) |> process_tags()
    changeset |> put_change(:tags, tags)
  end

  defp process_tags(tags_string) when tags_string |> is_binary() do
    tags_string
    |> String.split([",", " "], trim: true)
    |> Enum.map(fn str -> str |> String.trim() end)
    |> Enum.reject(fn str -> str in [nil, ""] end)
    |> Enum.sort()
  end

  defp process_tags(_other_tags_string), do: []

  @spec get_tags_string([String.t()] | nil) :: String.t()
  def get_tags_string(nil), do: ""
  def get_tags_string(tags) when tags |> is_list(), do: tags |> Enum.join(",")
end
