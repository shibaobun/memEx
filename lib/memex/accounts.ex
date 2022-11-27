defmodule Memex.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Memex.{Mailer, Repo}
  alias Memex.Accounts.{User, UserToken}
  alias Ecto.{Changeset, Multi}
  alias Oban.Job

  ## Database getters

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  @spec get_user_by_email(email :: String.t()) :: User.t() | nil
  def get_user_by_email(email) when is_binary(email), do: Repo.get_by(User, email: email)

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      %User{}

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

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_user!(User.t()) :: User.t()
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Returns all users grouped by role.

  ## Examples

      iex> list_users_by_role(%User{id: 123, role: :admin})
      [admin: [%User{}], user: [%User{}, %User{}]]

  """
  @spec list_all_users_by_role(User.t()) :: %{String.t() => [User.t()]}
  def list_all_users_by_role(%User{role: :admin}) do
    Repo.all(from u in User, order_by: u.email) |> Enum.group_by(fn user -> user.role end)
  end

  @doc """
  Returns all users for a certain role.

  ## Examples

      iex> list_users_by_role(%User{id: 123, role: :admin})
      [%User{}]

  """
  @spec list_users_by_role(User.role()) :: [User.t()]
  def list_users_by_role(role) do
    role = role |> to_string()
    Repo.all(from u in User, where: u.role == ^role, order_by: u.email)
  end

  ## User registration

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Changeset{}}

  """
  @spec register_user(attrs :: map()) :: {:ok, User.t()} | {:error, User.changeset()}
  def register_user(attrs) do
    Multi.new()
    |> Multi.one(:users_count, from(u in User, select: count(u.id), distinct: true))
    |> Multi.insert(:add_user, fn %{users_count: count} ->
      # if no registered users, make first user an admin
      role = if count == 0, do: "admin", else: "user"

      User.registration_changeset(attrs) |> User.role_changeset(role)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{add_user: user}} -> {:ok, user}
      {:error, :add_user, changeset, _changes_so_far} -> {:error, changeset}
    end
  end

  @doc """
  Returns an `%Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user_registration(user)
      %Changeset{data: %User{}}

  """
  @spec change_user_registration() :: User.changeset()
  @spec change_user_registration(attrs :: map()) :: User.changeset()
  def change_user_registration(attrs \\ %{}),
    do: User.registration_changeset(attrs, hash_password: false)

  ## Settings

  @doc """
  Returns an `%Changeset{}` for changing the user email.

  ## Examples

      iex> change_user_email(user)
      %Changeset{data: %User{}}

  """
  @spec change_user_email(User.t(), attrs :: map()) :: User.changeset()
  def change_user_email(user, attrs \\ %{}), do: User.email_changeset(user, attrs)

  @doc """
  Returns an `%Changeset{}` for changing the user role.

  ## Examples

      iex> change_user_role(user)
      %Changeset{data: %User{}}

  """
  @spec change_user_role(User.t(), User.role()) :: User.changeset()
  def change_user_role(user, role), do: User.role_changeset(user, role)

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_user_email(user, "valid password", %{email: ...})
      {:ok, %User{}}

      iex> apply_user_email(user, "invalid password", %{email: ...})
      {:error, %Changeset{}}

  """
  @spec apply_user_email(User.t(), password :: String.t(), attrs :: map()) ::
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
      _ -> :error
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

      iex> deliver_update_email_instructions(user, current_email, &Routes.user_update_email_url(conn, :edit, &1))
      {:ok, %{to: ..., body: ...}}

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

      iex> change_user_password(user)
      %Changeset{data: %User{}}

  """
  @spec change_user_password(User.t(), attrs :: map()) :: User.changeset()
  def change_user_password(user, attrs \\ %{}),
    do: User.password_changeset(user, attrs, hash_password: false)

  @doc """
  Updates the user password.

  ## Examples

      iex> update_user_password(user, "valid password", %{password: ...})
      {:ok, %User{}}

      iex> update_user_password(user, "invalid password", %{password: ...})
      {:error, %Changeset{}}

  """
  @spec update_user_password(User.t(), password :: String.t(), attrs :: map()) ::
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
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  @doc """
  Returns an `%Changeset{}` for changing the user locale.

  ## Examples

      iex> change_user_locale(user)
      %Changeset{data: %User{}}

  """
  @spec change_user_locale(User.t()) :: User.changeset()
  def change_user_locale(%{locale: locale} = user), do: User.locale_changeset(user, locale)

  @doc """
  Updates the user locale.

  ## Examples

      iex> update_user_locale(user, "valid locale")
      {:ok, %User{}}

      iex> update_user_password(user, "invalid locale")
      {:error, %Changeset{}}

  """
  @spec update_user_locale(User.t(), locale :: String.t()) ::
          {:ok, User.t()} | {:error, User.changeset()}
  def update_user_locale(user, locale),
    do: user |> User.locale_changeset(locale) |> Repo.update()

  @doc """
  Deletes a user. must be performed by an admin or the same user!

  ## Examples

      iex> delete_user!(user_to_delete, %User{id: 123, role: :admin})
      %User{}

      iex> delete_user!(%User{id: 123}, %User{id: 123})
      %User{}

  """
  @spec delete_user!(user_to_delete :: User.t(), User.t()) :: User.t()
  def delete_user!(user, %User{role: :admin}), do: user |> Repo.delete!()
  def delete_user!(%User{id: user_id} = user, %User{id: user_id}), do: user |> Repo.delete!()

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
    Repo.delete_all(UserToken.token_and_context_query(token, "session"))
    :ok
  end

  @doc """
  Returns a boolean if registration is allowed or not
  """
  @spec allow_registration?() :: boolean()
  def allow_registration? do
    Application.get_env(:memex, MemexWeb.Endpoint)[:registration] == "public" or
      list_users_by_role(:admin) |> Enum.empty?()
  end

  @doc """
  Checks if user is an admin
  """
  @spec is_admin?(User.t()) :: boolean()
  def is_admin?(%User{id: user_id}) do
    Repo.exists?(from u in User, where: u.id == ^user_id and u.role == :admin)
  end

  @doc """
  Checks to see if user has the admin role
  """
  @spec is_already_admin?(User.t() | nil) :: boolean()
  def is_already_admin?(%User{role: :admin}), do: true
  def is_already_admin?(_invalid_user), do: false

  ## Confirmation

  @doc """
  Delivers the confirmation email instructions to the given user.

  ## Examples

      iex> deliver_user_confirmation_instructions(user, &Routes.user_confirmation_url(conn, :confirm, &1))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_user_confirmation_instructions(confirmed_user, &Routes.user_confirmation_url(conn, :confirm, &1))
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
  @spec confirm_user(token :: String.t()) :: {:ok, User.t()} | atom()
  def confirm_user(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "confirm"),
         %User{} = user <- Repo.one(query),
         {:ok, %{user: user}} <- Repo.transaction(confirm_user_multi(user)) do
      {:ok, user}
    else
      _ -> :error
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

      iex> deliver_user_reset_password_instructions(user, &Routes.user_reset_password_url(conn, :edit, &1))
      {:ok, %{to: ..., body: ...}}

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

      iex> get_user_by_reset_password_token("validtoken")
      %User{}

      iex> get_user_by_reset_password_token("invalidtoken")
      nil

  """
  @spec get_user_by_reset_password_token(token :: String.t()) :: User.t() | nil
  def get_user_by_reset_password_token(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "reset_password"),
         %User{} = user <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Resets the user password.

  ## Examples

      iex> reset_user_password(user, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %User{}}

      iex> reset_user_password(user, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Changeset{}}

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
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end
end
