defmodule Memex.Notes do
  @moduledoc """
  The Notes context.
  """

  import Ecto.Query, warn: false
  alias Ecto.Changeset
  alias Memex.{Accounts.User, Notes.Note, Repo}

  @doc """
  Returns the list of notes.

  ## Examples

      iex> list_notes(%User{id: 123})
      [%Note{}, ...]

      iex> list_notes("my note", %User{id: 123})
      [%Note{slug: "my note"}, ...]

  """
  @spec list_notes(User.t()) :: [Note.t()]
  @spec list_notes(search :: String.t() | nil, User.t()) :: [Note.t()]
  def list_notes(search \\ nil, user)

  def list_notes(search, %{id: user_id}) when search |> is_nil() or search == "" do
    Repo.all(from n in Note, where: n.user_id == ^user_id, order_by: n.slug)
  end

  def list_notes(search, %{id: user_id}) when search |> is_binary() do
    trimmed_search = String.trim(search)

    Repo.all(
      from n in Note,
        where: n.user_id == ^user_id,
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
  Returns the list of public notes for viewing

  ## Examples

      iex> list_public_notes()
      [%Note{}, ...]

      iex> list_public_notes("my note")
      [%Note{slug: "my note"}, ...]
  """
  @spec list_public_notes() :: [Note.t()]
  @spec list_public_notes(search :: String.t() | nil) :: [Note.t()]
  def list_public_notes(search \\ nil)

  def list_public_notes(search) when search |> is_nil() or search == "" do
    Repo.all(from n in Note, where: n.visibility == :public, order_by: n.slug)
  end

  def list_public_notes(search) when search |> is_binary() do
    trimmed_search = String.trim(search)

    Repo.all(
      from n in Note,
        where: n.visibility == :public,
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
  Gets a single note.

  Raises `Ecto.NoResultsError` if the Note does not exist.

  ## Examples

      iex> get_note!(123, %User{id: 123})
      %Note{}

      iex> get_note!(456, %User{id: 123})
      ** (Ecto.NoResultsError)

  """
  @spec get_note!(Note.id(), User.t()) :: Note.t()
  def get_note!(id, %{id: user_id}) do
    Repo.one!(
      from n in Note,
        where: n.id == ^id,
        where: n.user_id == ^user_id or n.visibility in [:public, :unlisted]
    )
  end

  def get_note!(id, _invalid_user) do
    Repo.one!(
      from n in Note,
        where: n.id == ^id,
        where: n.visibility in [:public, :unlisted]
    )
  end

  @doc """
  Gets a single note by slug.

  Raises `Ecto.NoResultsError` if the Note does not exist.

  ## Examples

      iex> get_note_by_slug("my-note", %User{id: 123})
      %Note{}

      iex> get_note_by_slug("my-note", %User{id: 123})
      ** (Ecto.NoResultsError)

  """
  @spec get_note_by_slug(Note.slug(), User.t()) :: Note.t() | nil
  def get_note_by_slug(slug, %{id: user_id}) do
    Repo.one(
      from n in Note,
        where: n.slug == ^slug,
        where: n.user_id == ^user_id or n.visibility in [:public, :unlisted]
    )
  end

  def get_note_by_slug(slug, _invalid_user) do
    Repo.one(
      from n in Note,
        where: n.slug == ^slug,
        where: n.visibility in [:public, :unlisted]
    )
  end

  @doc """
  Creates a note.

  ## Examples

      iex> create_note(%{field: value}, %User{id: 123})
      {:ok, %Note{}}

      iex> create_note(%{field: bad_value}, %User{id: 123})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_note(User.t()) :: {:ok, Note.t()} | {:error, Note.changeset()}
  @spec create_note(attrs :: map(), User.t()) :: {:ok, Note.t()} | {:error, Note.changeset()}
  def create_note(attrs \\ %{}, user) do
    Note.create_changeset(attrs, user) |> Repo.insert()
  end

  @doc """
  Updates a note.

  ## Examples

      iex> update_note(note, %{field: new_value}, %User{id: 123})
      {:ok, %Note{}}

      iex> update_note(note, %{field: bad_value}, %User{id: 123})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_note(Note.t(), attrs :: map(), User.t()) ::
          {:ok, Note.t()} | {:error, Note.changeset()}
  def update_note(%Note{} = note, attrs, user) do
    note
    |> Note.update_changeset(attrs, user)
    |> Repo.update()
  end

  @doc """
  Deletes a note.

  ## Examples

      iex> delete_note(%Note{user_id: 123}, %User{id: 123})
      {:ok, %Note{}}

      iex> delete_note(%Note{}, %User{role: :admin})
      {:ok, %Note{}}

      iex> delete_note(%Note{}, %User{id: 123})
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_note(Note.t(), User.t()) :: {:ok, Note.t()} | {:error, Note.changeset()}
  def delete_note(%Note{user_id: user_id} = note, %{id: user_id}) do
    note |> Repo.delete()
  end

  def delete_note(%Note{} = note, %{role: :admin}) do
    note |> Repo.delete()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking note changes.

  ## Examples

      iex> change_note(note, %User{id: 123})
      %Ecto.Changeset{data: %Note{}}

      iex> change_note(note, %{slug: "new slug"}, %User{id: 123})
      %Ecto.Changeset{data: %Note{}}

  """
  @spec change_note(Note.t(), User.t()) :: Note.changeset()
  @spec change_note(Note.t(), attrs :: map(), User.t()) :: Note.changeset()
  def change_note(%Note{} = note, attrs \\ %{}, user) do
    note |> Note.update_changeset(attrs, user)
  end

  @doc """
  Gets a canonical string representation of the `:tags` field for a Note
  """
  @spec get_tags_string(Note.t() | Note.changeset() | [String.t()] | nil) :: String.t()
  def get_tags_string(nil), do: ""
  def get_tags_string(tags) when tags |> is_list(), do: tags |> Enum.join(",")
  def get_tags_string(%Note{tags: tags}), do: tags |> get_tags_string()

  def get_tags_string(%Changeset{} = changeset) do
    changeset
    |> Changeset.get_field(:tags)
    |> get_tags_string()
  end
end
