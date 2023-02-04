defmodule Memex.Accounts.Invite do
  @moduledoc """
  An invite, created by an admin to allow someone to join their instance. An
  invite can be enabled or disabled, and can have an optional number of uses if
  `:uses_left` is defined.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.{Association, Changeset, UUID}
  alias Memex.Accounts.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "invites" do
    field :name, :string
    field :token, :string
    field :uses_left, :integer, default: nil
    field :disabled_at, :naive_datetime

    belongs_to :created_by, User

    has_many :users, User

    timestamps()
  end

  @type t :: %__MODULE__{
          id: id(),
          name: String.t(),
          token: token(),
          uses_left: integer() | nil,
          disabled_at: NaiveDateTime.t(),
          created_by: User.t() | nil | Association.NotLoaded.t(),
          created_by_id: User.id() | nil,
          users: [User.t()] | Association.NotLoaded.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }
  @type new_invite :: %__MODULE__{}
  @type id :: UUID.t()
  @type changeset :: Changeset.t(t() | new_invite())
  @type token :: String.t()

  @doc false
  @spec create_changeset(User.t(), token(), attrs :: map()) :: changeset()
  def create_changeset(%User{id: user_id}, token, attrs) do
    %__MODULE__{}
    |> change(token: token, created_by_id: user_id)
    |> cast(attrs, [:name, :uses_left, :disabled_at])
    |> validate_required([:name, :token, :created_by_id])
    |> validate_number(:uses_left, greater_than_or_equal_to: 0)
  end

  @doc false
  @spec update_changeset(t() | new_invite(), attrs :: map()) :: changeset()
  def update_changeset(invite, attrs) do
    invite
    |> cast(attrs, [:name, :uses_left, :disabled_at])
    |> validate_required([:name])
    |> validate_number(:uses_left, greater_than_or_equal_to: 0)
  end
end
