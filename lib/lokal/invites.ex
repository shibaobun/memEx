defmodule Lokal.Invites do
  @moduledoc """
  The Invites context.
  """

  import Ecto.Query, warn: false
  alias Lokal.{Accounts.User, Invites.Invite, Repo}
  alias Ecto.Changeset

  @invite_token_length 20

  @doc """
  Returns the list of invites.

  ## Examples

      iex> list_invites(%User{id: 123, role: :admin})
      [%Invite{}, ...]

  """
  @spec list_invites(User.t()) :: [Invite.t()]
  def list_invites(%User{role: :admin}) do
    Repo.all(from i in Invite, order_by: i.name)
  end

  @doc """
  Gets a single invite.

  Raises `Ecto.NoResultsError` if the Invite does not exist.

  ## Examples

      iex> get_invite!(123, %User{id: 123, role: :admin})
      %Invite{}

      iex> get_invite!(456, %User{id: 123, role: :admin})
      ** (Ecto.NoResultsError)

  """
  @spec get_invite!(Invite.id(), User.t()) :: Invite.t()
  def get_invite!(id, %User{role: :admin}) do
    Repo.get!(Invite, id)
  end

  @doc """
  Returns a valid invite or nil based on the attempted token

  ## Examples

      iex> get_invite_by_token("valid_token")
      %Invite{}

      iex> get_invite_by_token("invalid_token")
      nil
  """
  @spec get_invite_by_token(token :: String.t() | nil) :: Invite.t() | nil
  def get_invite_by_token(nil), do: nil
  def get_invite_by_token(""), do: nil

  def get_invite_by_token(token) do
    Repo.one(
      from(i in Invite,
        where: i.token == ^token and i.disabled_at |> is_nil()
      )
    )
  end

  @doc """
  Uses invite by decrementing uses_left, or marks invite invalid if it's been
  completely used.
  """
  @spec use_invite!(Invite.t()) :: Invite.t()
  def use_invite!(%Invite{uses_left: nil} = invite), do: invite

  def use_invite!(%Invite{uses_left: uses_left} = invite) do
    new_uses_left = uses_left - 1

    attrs =
      if new_uses_left <= 0 do
        now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
        %{"uses_left" => 0, "disabled_at" => now}
      else
        %{"uses_left" => new_uses_left}
      end

    invite |> Invite.update_changeset(attrs) |> Repo.update!()
  end

  @doc """
  Creates a invite.

  ## Examples

      iex> create_invite(%User{id: 123, role: :admin}, %{field: value})
      {:ok, %Invite{}}

      iex> create_invite(%User{id: 123, role: :admin}, %{field: bad_value})
      {:error, %Changeset{}}

  """
  @spec create_invite(User.t(), attrs :: map()) ::
          {:ok, Invite.t()} | {:error, Changeset.t(Invite.new_invite())}
  def create_invite(%User{id: user_id, role: :admin}, attrs) do
    token =
      :crypto.strong_rand_bytes(@invite_token_length)
      |> Base.url_encode64()
      |> binary_part(0, @invite_token_length)

    attrs = attrs |> Map.merge(%{"user_id" => user_id, "token" => token})

    %Invite{} |> Invite.create_changeset(attrs) |> Repo.insert()
  end

  @doc """
  Updates a invite.

  ## Examples

      iex> update_invite(invite, %{field: new_value}, %User{id: 123, role: :admin})
      {:ok, %Invite{}}

      iex> update_invite(invite, %{field: bad_value}, %User{id: 123, role: :admin})
      {:error, %Changeset{}}

  """
  @spec update_invite(Invite.t(), attrs :: map(), User.t()) ::
          {:ok, Invite.t()} | {:error, Changeset.t(Invite.t())}
  def update_invite(invite, attrs, %User{role: :admin}),
    do: invite |> Invite.update_changeset(attrs) |> Repo.update()

  @doc """
  Deletes a invite.

  ## Examples

      iex> delete_invite(invite, %User{id: 123, role: :admin})
      {:ok, %Invite{}}

      iex> delete_invite(invite, %User{id: 123, role: :admin})
      {:error, %Changeset{}}

  """
  @spec delete_invite(Invite.t(), User.t()) ::
          {:ok, Invite.t()} | {:error, Changeset.t(Invite.t())}
  def delete_invite(invite, %User{role: :admin}), do: invite |> Repo.delete()

  @doc """
  Deletes a invite.

  ## Examples

      iex> delete_invite(invite, %User{id: 123, role: :admin})
      %Invite{}

  """
  @spec delete_invite!(Invite.t(), User.t()) :: Invite.t()
  def delete_invite!(invite, %User{role: :admin}), do: invite |> Repo.delete!()

  @doc """
  Returns an `%Changeset{}` for tracking invite changes.

  ## Examples

      iex> change_invite(invite)
      %Changeset{data: %Invite{}}

  """
  @spec change_invite(Invite.t() | Invite.new_invite()) ::
          Changeset.t(Invite.t() | Invite.new_invite())
  @spec change_invite(Invite.t() | Invite.new_invite(), attrs :: map()) ::
          Changeset.t(Invite.t() | Invite.new_invite())
  def change_invite(invite, attrs \\ %{}), do: invite |> Invite.update_changeset(attrs)
end
