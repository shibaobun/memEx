defmodule Memex.Contexts do
  @moduledoc """
  The Contexts context.
  """

  import Ecto.Query, warn: false
  alias Ecto.Changeset
  alias Memex.{Accounts.User, Contexts.Context, Repo}

  @doc """
  Returns the list of contexts.

  ## Examples

      iex> list_contexts(%User{id: 123})
      [%Context{}, ...]

      iex> list_contexts("my context", %User{id: 123})
      [%Context{slug: "my context"}, ...]

  """
  @spec list_contexts(User.t()) :: [Context.t()]
  @spec list_contexts(search :: String.t() | nil, User.t()) :: [Context.t()]
  def list_contexts(search \\ nil, user)

  def list_contexts(search, %{id: user_id}) when search |> is_nil() or search == "" do
    Repo.all(from c in Context, where: c.user_id == ^user_id, order_by: c.slug)
  end

  def list_contexts(search, %{id: user_id}) when search |> is_binary() do
    trimmed_search = String.trim(search)

    Repo.all(
      from c in Context,
        where: c.user_id == ^user_id,
        where:
          fragment(
            "search @@ websearch_to_tsquery('english', ?)",
            ^trimmed_search
          ),
        order_by: {
          :desc,
          fragment(
            "ts_rank_cd(search, websearch_to_tsquery('english', ?), 4)",
            ^trimmed_search
          )
        }
    )
  end

  @doc """
  Returns the list of public contexts for viewing.

  ## Examples

      iex> list_public_contexts()
      [%Context{}, ...]

      iex> list_public_contexts("my context")
      [%Context{slug: "my context"}, ...]

  """
  @spec list_public_contexts() :: [Context.t()]
  @spec list_public_contexts(search :: String.t() | nil) :: [Context.t()]
  def list_public_contexts(search \\ nil)

  def list_public_contexts(search) when search |> is_nil() or search == "" do
    Repo.all(from c in Context, where: c.visibility == :public, order_by: c.slug)
  end

  def list_public_contexts(search) when search |> is_binary() do
    trimmed_search = String.trim(search)

    Repo.all(
      from c in Context,
        where: c.visibility == :public,
        where:
          fragment(
            "search @@ websearch_to_tsquery('english', ?)",
            ^trimmed_search
          ),
        order_by: {
          :desc,
          fragment(
            "ts_rank_cd(search, websearch_to_tsquery('english', ?), 4)",
            ^trimmed_search
          )
        }
    )
  end

  @doc """
  Gets a single context.

  Raises `Ecto.NoResultsError` if the Context does not exist.

  ## Examples

      iex> get_context!(123, %User{id: 123})
      %Context{}

      iex> get_context!(456, %User{id: 123})
      ** (Ecto.NoResultsError)

  """
  @spec get_context!(Context.id(), User.t()) :: Context.t()
  def get_context!(id, %{id: user_id}) do
    Repo.one!(
      from c in Context,
        where: c.id == ^id,
        where: c.user_id == ^user_id or c.visibility in [:public, :unlisted]
    )
  end

  def get_context!(id, _invalid_user) do
    Repo.one!(
      from c in Context,
        where: c.id == ^id,
        where: c.visibility in [:public, :unlisted]
    )
  end

  @doc """
  Gets a single context by a slug.

  Raises `Ecto.NoResultsError` if the Context does not exist.

  ## Examples

      iex> get_context_by_slug("my-context", %User{id: 123})
      %Context{}

      iex> get_context_by_slug("my-context", %User{id: 123})
      ** (Ecto.NoResultsError)

  """
  @spec get_context_by_slug(Context.slug(), User.t()) :: Context.t() | nil
  def get_context_by_slug(slug, %{id: user_id}) do
    Repo.one(
      from c in Context,
        where: c.slug == ^slug,
        where: c.user_id == ^user_id or c.visibility in [:public, :unlisted]
    )
  end

  def get_context_by_slug(slug, _invalid_user) do
    Repo.one(
      from c in Context,
        where: c.slug == ^slug,
        where: c.visibility in [:public, :unlisted]
    )
  end

  @doc """
  Creates a context.

  ## Examples

      iex> create_context(%{field: value}, %User{id: 123})
      {:ok, %Context{}}

      iex> create_context(%{field: bad_value}, %User{id: 123})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_context(User.t()) :: {:ok, Context.t()} | {:error, Context.changeset()}
  @spec create_context(attrs :: map(), User.t()) ::
          {:ok, Context.t()} | {:error, Context.changeset()}
  def create_context(attrs \\ %{}, user) do
    Context.create_changeset(attrs, user) |> Repo.insert()
  end

  @doc """
  Updates a context.

  ## Examples

      iex> update_context(context, %{field: new_value}, %User{id: 123})
      {:ok, %Context{}}

      iex> update_context(context, %{field: bad_value}, %User{id: 123})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_context(Context.t(), attrs :: map(), User.t()) ::
          {:ok, Context.t()} | {:error, Context.changeset()}
  def update_context(%Context{} = context, attrs, user) do
    context
    |> Context.update_changeset(attrs, user)
    |> Repo.update()
  end

  @doc """
  Deletes a context.

  ## Examples

      iex> delete_context(%Context{user_id: 123}, %User{id: 123})
      {:ok, %Context{}}

      iex> delete_context(%Context{user_id: 123}, %User{role: :admin})
      {:ok, %Context{}}

      iex> delete_context(%Context{}, %User{id: 123})
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_context(Context.t(), User.t()) ::
          {:ok, Context.t()} | {:error, Context.changeset()}
  def delete_context(%Context{user_id: user_id} = context, %{id: user_id}) do
    context |> Repo.delete()
  end

  def delete_context(%Context{} = context, %{role: :admin}) do
    context |> Repo.delete()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking context changes.

  ## Examples

      iex> change_context(context)
      %Ecto.Changeset{data: %Context{}}

  """
  @spec change_context(Context.t(), User.t()) :: Context.changeset()
  @spec change_context(Context.t(), attrs :: map(), User.t()) :: Context.changeset()
  def change_context(%Context{} = context, attrs \\ %{}, user) do
    context |> Context.update_changeset(attrs, user)
  end

  @doc """
  Gets a canonical string representation of the `:tags` field for a Note
  """
  @spec get_tags_string(Context.t() | Context.changeset() | [String.t()] | nil) :: String.t()
  def get_tags_string(nil), do: ""
  def get_tags_string(tags) when tags |> is_list(), do: tags |> Enum.join(",")
  def get_tags_string(%Context{tags: tags}), do: tags |> get_tags_string()

  def get_tags_string(%Changeset{} = changeset) do
    changeset
    |> Changeset.get_field(:tags)
    |> get_tags_string()
  end
end
