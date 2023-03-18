defmodule Memex.Accounts.Invites do
  @moduledoc """
  The Invites context.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias Memex.Accounts.{Invite, User}
  alias Memex.Repo

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
  Gets a single invite for a user

  Raises `Ecto.NoResultsError` if the Invite does not exist.

  ## Examples

      iex> get_invite!(123, %User{id: 123, role: :admin})
      %Invite{}

      > get_invite!(456, %User{id: 123, role: :admin})
      ** (Ecto.NoResultsError)

  """
  @spec get_invite!(Invite.id(), User.t()) :: Invite.t()
  def get_invite!(id, %User{role: :admin}) do
    Repo.get!(Invite, id)
  end

  @doc """
  Returns if an invite token is still valid

  ## Examples

      iex> valid_invite_token?("valid_token")
      %Invite{}

      iex> valid_invite_token?("invalid_token")
      nil
  """
  @spec valid_invite_token?(Invite.token() | nil) :: boolean()
  def valid_invite_token?(token) when token in [nil, ""], do: false

  def valid_invite_token?(token) do
    Repo.exists?(
      from i in Invite,
        where: i.token == ^token,
        where: i.disabled_at |> is_nil()
    )
  end

  @doc """
  Uses invite by decrementing uses_left, or marks invite invalid if it's been
  completely used.
  """
  @spec use_invite(Invite.token()) :: {:ok, Invite.t()} | {:error, :invalid_token}
  def use_invite(invite_token) do
    Multi.new()
    |> Multi.run(:invite, fn _changes_so_far, _repo ->
      invite_token |> get_invite_by_token()
    end)
    |> Multi.update(:decrement_invite, fn %{invite: invite} ->
      decrement_invite_changeset(invite)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{decrement_invite: invite}} -> {:ok, invite}
      {:error, :invite, :invalid_token, _changes_so_far} -> {:error, :invalid_token}
    end
  end

  @spec get_invite_by_token(Invite.token() | nil) :: {:ok, Invite.t()} | {:error, :invalid_token}
  defp get_invite_by_token(token) when token in [nil, ""], do: {:error, :invalid_token}

  defp get_invite_by_token(token) do
    Repo.one(
      from i in Invite,
        where: i.token == ^token,
        where: i.disabled_at |> is_nil()
    )
    |> case do
      nil -> {:error, :invalid_token}
      invite -> {:ok, invite}
    end
  end

  @spec get_use_count(Invite.t(), User.t()) :: non_neg_integer() | nil
  def get_use_count(%Invite{id: invite_id} = invite, user) do
    [invite] |> get_use_counts(user) |> Map.get(invite_id)
  end

  @spec get_use_counts([Invite.t()], User.t()) ::
          %{optional(Invite.id()) => non_neg_integer()}
  def get_use_counts(invites, %User{role: :admin}) do
    invite_ids = invites |> Enum.map(fn %{id: invite_id} -> invite_id end)

    Repo.all(
      from u in User,
        where: u.invite_id in ^invite_ids,
        group_by: u.invite_id,
        select: {u.invite_id, count(u.id)}
    )
    |> Map.new()
  end

  @spec decrement_invite_changeset(Invite.t()) :: Invite.changeset()
  defp decrement_invite_changeset(%Invite{uses_left: nil} = invite) do
    invite |> Invite.update_changeset(%{})
  end

  defp decrement_invite_changeset(%Invite{uses_left: 1} = invite) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    invite |> Invite.update_changeset(%{uses_left: 0, disabled_at: now})
  end

  defp decrement_invite_changeset(%Invite{uses_left: uses_left} = invite) do
    invite |> Invite.update_changeset(%{uses_left: uses_left - 1})
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
          {:ok, Invite.t()} | {:error, Invite.changeset()}
  def create_invite(%User{role: :admin} = user, attrs) do
    token =
      :crypto.strong_rand_bytes(@invite_token_length)
      |> Base.url_encode64()
      |> binary_part(0, @invite_token_length)

    Invite.create_changeset(user, token, attrs) |> Repo.insert()
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
          {:ok, Invite.t()} | {:error, Invite.changeset()}
  def update_invite(invite, attrs, %User{role: :admin}) do
    invite |> Invite.update_changeset(attrs) |> Repo.update()
  end

  @doc """
  Deletes a invite.

  ## Examples

      iex> delete_invite(invite, %User{id: 123, role: :admin})
      {:ok, %Invite{}}

      iex> delete_invite(invite, %User{id: 123, role: :admin})
      {:error, %Changeset{}}

  """
  @spec delete_invite(Invite.t(), User.t()) ::
          {:ok, Invite.t()} | {:error, Invite.changeset()}
  def delete_invite(invite, %User{role: :admin}) do
    invite |> Repo.delete()
  end

  @doc """
  Deletes a invite.

  ## Examples

      iex> delete_invite(invite, %User{id: 123, role: :admin})
      %Invite{}

  """
  @spec delete_invite!(Invite.t(), User.t()) :: Invite.t()
  def delete_invite!(invite, %User{role: :admin}) do
    invite |> Repo.delete!()
  end
end
