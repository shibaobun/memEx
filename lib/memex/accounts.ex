defmodule Memex.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Memex.{Mailer, Repo}
  alias Memex.Accounts.{Invite, Invites, User, UserToken}
  alias Ecto.{Changeset, Multi}
  alias Oban.Job

  ## Database getters

  @doc """
  Gets a user by email.

  ## Examples

      iex> register_user(%{email: "foo@example.com", password: "valid_password"})
      iex> with %User{} <- get_user_by_email("foo@example.com"), do: :passed
      :passed

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  @spec get_user_by_email(email :: String.t()) :: User.t() | nil
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> register_user(%{email: "foo@example.com", password: "valid_password"})
      iex> with %User{} <- get_user_by_email_and_password("foo@example.com", "valid_password"), do: :passed
      :passed

      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  @spec get_user_by_email_and_password(email :: String.t(), password :: String.t()) ::
          User.t() | nil
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> {:ok, user} = register_user(%{email: "foo@example.com", password: "valid_password"})
      iex> get_user!(user.id)
      user

      > get_user!()
      ** (Ecto.NoResultsError)

  """
  @spec get_user!(User.t()) :: User.t()
  def get_user!(id) do
    Repo.get!(User, id)
  end

  @doc """
  Returns all users grouped by role.

  ## Examples

      iex> {:ok, user1} = register_user(%{email: "foo1@example.com", password: "valid_password"})
      iex> {:ok, user2} = register_user(%{email: "foo2@example.com", password: "valid_password"})
      iex> with %{admin: [^user1], user: [^user2]} <- list_all_users_by_role(user1), do: :passed
      :passed

  """
  @spec list_all_users_by_role(User.t()) :: %{User.role() => [User.t()]}
  def list_all_users_by_role(%User{role: :admin}) do
    Repo.all(from u in User, order_by: u.email) |> Enum.group_by(fn %{role: role} -> role end)
  end

  @doc """
  Returns all users for a certain role.

  ## Examples

      iex> {:ok, user} = register_user(%{email: "foo@example.com", password: "valid_password"})
      iex> with [^user] <- list_users_by_role(:admin), do: :passed
      :passed

  """
  @spec list_users_by_role(:admin) :: [User.t()]
  def list_users_by_role(:admin = role) do
    Repo.all(from u in User, where: u.role == ^role, order_by: u.email)
  end

  ## User registration

  @doc """
  Registers a user.

  ## Examples

      iex> with {:ok, %User{email: "foo@example.com"}} <-
      ...>        register_user(%{email: "foo@example.com", password: "valid_password"}),
      ...>      do: :passed
      :passed

      iex> with {:error, %Changeset{}} <- register_user(%{email: "foo@example"}), do: :passed
      :passed

  """
  @spec register_user(attrs :: map(), Invite.token() | nil) ::
          {:ok, User.t()} | {:error, :invalid_token | User.changeset()}
  def register_user(attrs, invite_token \\ nil) do
    Multi.new()
    |> Multi.one(:users_count, from(u in User, select: count(u.id), distinct: true))
    |> Multi.run(:use_invite, fn _changes_so_far, _repo ->
      if allow_registration?() and invite_token |> is_nil() do
        {:ok, nil}
      else
        Invites.use_invite(invite_token)
      end
    end)
    |> Multi.insert(:add_user, fn %{users_count: count, use_invite: invite} ->
      # if no registered users, make first user an admin
      role = if count == 0, do: :admin, else: :user
      User.registration_changeset(attrs, invite) |> User.role_changeset(role)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{add_user: user}} -> {:ok, user}
      {:error, :use_invite, :invalid_token, _changes_so_far} -> {:error, :invalid_token}
      {:error, :add_user, changeset, _changes_so_far} -> {:error, changeset}
    end
  end

  @doc """
  Returns an `%Changeset{}` for tracking user changes.

  ## Examples

      iex> with %Changeset{} <- change_user_registration(), do: :passed
      :passed

      iex> with %Changeset{} <- change_user_registration(%{password: "hi"}), do: :passed
      :passed

  """
  @spec change_user_registration() :: User.changeset()
  @spec change_user_registration(attrs :: map()) :: User.changeset()
  def change_user_registration(attrs \\ %{}) do
    User.registration_changeset(attrs, nil, hash_password: false)
  end

  ## Settings

  @doc """
  Returns an `%Changeset{}` for changing the user email.

  ## Examples

      iex> with %Changeset{} <- change_user_email(%User{email: "foo@example.com"}), do: :passed
      :passed

  """
  @spec change_user_email(User.t()) :: User.changeset()
  @spec change_user_email(User.t(), attrs :: map()) :: User.changeset()
  def change_user_email(user, attrs \\ %{}) do
    User.email_changeset(user, attrs)
  end

  @doc """
  Returns an `%Changeset{}` for changing the user role.

  ## Examples

      iex> with %Changeset{} <- change_user_role(%User{}, :user), do: :passed
      :passed

  """
  @spec change_user_role(User.t(), User.role()) :: User.changeset()
  def change_user_role(user, role) do
    User.role_changeset(user, role)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> {:ok, user} = register_user(%{email: "foo@example.com", password: "valid_password"})
      iex> with {:ok, %User{}} <-
      ...>        apply_user_email(user, "valid_password", %{email: "new_email@account.com"}),
      ...>      do: :passed
      :passed

      iex> {:ok, user} = register_user(%{email: "foo@example.com", password: "valid_password"})
      iex> with {:error, %Changeset{}} <-
      ...>        apply_user_email(user, "invalid password", %{email: "new_email@account"}),
      ...>      do: :passed
      :passed

  """
  @spec apply_user_email(User.t(), email :: String.t(), attrs :: map()) ::
          {:ok, User.t()} | {:error, User.changeset()}
  def apply_user_email(user, password, attrs) do
    user
    |> User.email_changeset(attrs)
    |> User.validate_current_password(password)
    |> Changeset.apply_action(:update)
  end

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  @spec update_user_email(User.t(), token :: String.t()) :: :ok | :error
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
         %UserToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(user_email_multi(user, email, context)) do
      :ok
    else
      _error_tuple -> :error
    end
  end

  @spec user_email_multi(User.t(), email :: String.t(), context :: String.t()) :: Multi.t()
  defp user_email_multi(user, email, context) do
    changeset = user |> User.email_changeset(%{email: email}) |> User.confirm_changeset()

    Multi.new()
    |> Multi.update(:user, changeset)
    |> Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, [context]))
  end

  @doc """
  Delivers the update email instructions to the given user.

  ## Examples

      iex> {:ok, %{id: user_id} = user} = register_user(%{email: "foo@example.com", password: "valid_password"})
      iex> with %Oban.Job{
      ...>        args: %{email: :update_email, user_id: ^user_id, attrs: %{url: "example url"}}
      ...>      } <- deliver_update_email_instructions(user, "new_foo@example.com", fn _token -> "example url" end),
      ...>      do: :passed
      :passed

  """
  @spec deliver_update_email_instructions(User.t(), current_email :: String.t(), function) ::
          Job.t()
  def deliver_update_email_instructions(user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")
    Repo.insert!(user_token)
    Mailer.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Changeset{}` for changing the user password.

  ## Examples

      iex> with %Changeset{} <- change_user_password(%User{}), do: :passed
      :passed

  """
  @spec change_user_password(User.t(), attrs :: map()) :: User.changeset()
  def change_user_password(user, attrs \\ %{}) do
    User.password_changeset(user, attrs, hash_password: false)
  end

  @doc """
  Updates the user password.

  ## Examples

      iex> {:ok, user} = register_user(%{email: "foo@example.com", password: "valid_password"})
      iex> with {:ok, %User{}} <-
      ...>         reset_user_password(user, %{
      ...>           password: "new password",
      ...>           password_confirmation: "new password"
      ...>         }),
      ...>      do: :passed
      :passed

      iex> {:ok, user} = register_user(%{email: "foo@example.com", password: "valid_password"})
      iex> with {:error, %Changeset{}} <-
      ...>        update_user_password(user, "invalid password", %{password: "123"}),
      ...>      do: :passed
      :passed

  """
  @spec update_user_password(User.t(), String.t(), attrs :: map()) ::
          {:ok, User.t()} | {:error, User.changeset()}
  def update_user_password(user, password, attrs) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> User.validate_current_password(password)

    Multi.new()
    |> Multi.update(:user, changeset)
    |> Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _changes_so_far} -> {:error, changeset}
    end
  end

  @doc """
  Returns an `Ecto.Changeset.t()` for changing the user locale.

  ## Examples

      iex> with %Changeset{} <- change_user_locale(%User{}), do: :passed
      :passed

  """
  @spec change_user_locale(User.t()) :: User.changeset()
  def change_user_locale(%{locale: locale} = user) do
    User.locale_changeset(user, locale)
  end

  @doc """
  Updates the user locale.

  ## Examples

      iex> {:ok, user} = register_user(%{email: "foo@example.com", password: "valid_password"})
      iex> with {:ok, %User{}} <- update_user_locale(user, "en_US"), do: :passed
      :passed

  """
  @spec update_user_locale(User.t(), locale :: String.t()) ::
          {:ok, User.t()} | {:error, User.changeset()}
  def update_user_locale(user, locale) do
    user |> User.locale_changeset(locale) |> Repo.update()
  end

  @doc """
  Deletes a user. must be performed by an admin or the same user!

  ## Examples

      iex> {:ok, user} = register_user(%{email: "foo@example.com", password: "valid_password"})
      iex> with %User{} <- delete_user!(user, %User{id: 123, role: :admin}), do: :passed
      :passed

      iex> {:ok, user} = register_user(%{email: "foo@example.com", password: "valid_password"})
      iex> with %User{} <- delete_user!(user, user), do: :passed
      :passed

  """
  @spec delete_user!(user_to_delete :: User.t(), User.t()) :: User.t()
  def delete_user!(user, %User{role: :admin}) do
    user |> Repo.delete!()
  end

  def delete_user!(%User{id: user_id} = user, %User{id: user_id}) do
    user |> Repo.delete!()
  end

  ## Session

  @doc """
  Generates a session token.
  """
  @spec generate_user_session_token(User.t()) :: String.t()
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.
  """
  @spec get_user_by_session_token(token :: String.t()) :: User.t()
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  @spec delete_session_token(token :: String.t()) :: :ok
  def delete_session_token(token) do
    UserToken.token_and_context_query(token, "session") |> Repo.delete_all()
    :ok
  end

  @doc """
  Returns a boolean if registration is allowed or not
  """
  @spec allow_registration?() :: boolean()
  def allow_registration? do
    Application.get_env(:memex, Memex.Accounts)[:registration] == "public" or
      list_users_by_role(:admin) |> Enum.empty?()
  end

  @doc """
  Checks if user is an admin

  ## Examples

      iex> {:ok, user} = register_user(%{email: "foo@example.com", password: "valid_password"})
      iex> is_admin?(user)
      true

      iex> is_admin?(%User{id: Ecto.UUID.generate()})
      false

  """
  @spec is_admin?(User.t()) :: boolean()
  def is_admin?(%User{id: user_id}) do
    Repo.exists?(from u in User, where: u.id == ^user_id, where: u.role == :admin)
  end

  @doc """
  Checks to see if user has the admin role

  ## Examples

      iex> {:ok, user} = register_user(%{email: "foo@example.com", password: "valid_password"})
      iex> is_already_admin?(user)
      true

      iex> is_already_admin?(%User{})
      false

  """
  @spec is_already_admin?(User.t() | nil) :: boolean()
  def is_already_admin?(%User{role: :admin}), do: true
  def is_already_admin?(_invalid_user), do: false

  ## Confirmation

  @doc """
  Delivers the confirmation email instructions to the given user.

  ## Examples

      iex> {:ok, %{id: user_id} = user} = register_user(%{email: "foo@example.com", password: "valid_password"})
      iex> with %Oban.Job{
      ...>   args: %{email: :welcome, user_id: ^user_id, attrs: %{url: "example url"}}
      ...> } <- deliver_user_confirmation_instructions(user, fn _token -> "example url" end),
      ...> do: :passed
      :passed

      iex> {:ok, user} = register_user(%{email: "foo@example.com", password: "valid_password"})
      iex> user = user |> User.confirm_changeset() |> Repo.update!()
      iex> deliver_user_confirmation_instructions(user, fn _token -> "example url" end)
      {:error, :already_confirmed}

  """
  @spec deliver_user_confirmation_instructions(User.t(), function) :: Job.t()
  def deliver_user_confirmation_instructions(user, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if user.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")
      Repo.insert!(user_token)
      Mailer.deliver_confirmation_instructions(user, confirmation_url_fun.(encoded_token))
    end
  end

  @doc """
  Confirms a user by the given token.

  If the token matches, the user account is marked as confirmed
  and the token is deleted.
  """
  @spec confirm_user(token :: String.t()) :: {:ok, User.t()} | :error
  def confirm_user(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "confirm"),
         %User{} = user <- Repo.one(query),
         {:ok, %{user: user}} <- Repo.transaction(confirm_user_multi(user)) do
      {:ok, user}
    else
      _error_tuple -> :error
    end
  end

  @spec confirm_user_multi(User.t()) :: Multi.t()
  def confirm_user_multi(user) do
    Multi.new()
    |> Multi.update(:user, User.confirm_changeset(user))
    |> Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, ["confirm"]))
  end

  ## Reset password

  @doc """
  Delivers the reset password email to the given user.

  ## Examples

      iex> {:ok, %{id: user_id} = user} = register_user(%{email: "foo@example.com", password: "valid_password"})
      iex> with %Oban.Job{args: %{
      ...>        email: :reset_password, user_id: ^user_id, attrs: %{url: "example url"}}
      ...>    } <- deliver_user_reset_password_instructions(user, fn _token -> "example url" end),
      ...>    do: :passed
      :passed

  """
  @spec deliver_user_reset_password_instructions(User.t(), function()) :: Job.t()
  def deliver_user_reset_password_instructions(user, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "reset_password")
    Repo.insert!(user_token)
    Mailer.deliver_reset_password_instructions(user, reset_password_url_fun.(encoded_token))
  end

  @doc """
  Gets the user by reset password token.

  ## Examples

      iex> {:ok, user} = register_user(%{email: "foo@example.com", password: "valid_password"})
      iex> {encoded_token, user_token} = UserToken.build_email_token(user, "reset_password")
      iex> Repo.insert!(user_token)
      iex> with %User{} <- get_user_by_reset_password_token(encoded_token), do: :passed
      :passed

      iex> get_user_by_reset_password_token("invalidtoken")
      nil

  """
  @spec get_user_by_reset_password_token(token :: String.t()) :: User.t() | nil
  def get_user_by_reset_password_token(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "reset_password"),
         %User{} = user <- Repo.one(query) do
      user
    else
      _error_tuple -> nil
    end
  end

  @doc """
  Resets the user password.

  ## Examples

      iex> {:ok, user} = register_user(%{email: "foo@example.com", password: "valid_password"})
      iex> with {:ok, %User{}} <-
      ...>         reset_user_password(user, %{
      ...>           password: "new password",
      ...>           password_confirmation: "new password"
      ...>         }),
      ...>      do: :passed
      :passed

      iex> {:ok, user} = register_user(%{email: "foo@example.com", password: "valid_password"})
      iex> with {:error, %Changeset{}} <-
      ...>        reset_user_password(user, %{password: "valid", password_confirmation: "not the same"}),
      ...>      do: :passed
      :passed

  """
  @spec reset_user_password(User.t(), attrs :: map()) ::
          {:ok, User.t()} | {:error, User.changeset()}
  def reset_user_password(user, attrs) do
    Multi.new()
    |> Multi.update(:user, User.password_changeset(user, attrs))
    |> Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _changes_so_far} -> {:error, changeset}
    end
  end
end
