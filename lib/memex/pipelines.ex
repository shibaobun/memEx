defmodule Memex.Pipelines do
  @moduledoc """
  The Pipelines context.
  """

  import Ecto.Query, warn: false
  alias Ecto.Changeset
  alias Memex.{Accounts.User, Pipelines.Pipeline, Repo}

  @doc """
  Returns the list of pipelines.

  ## Examples

      iex> list_pipelines(%User{id: 123})
      [%Pipeline{}, ...]

      iex> list_pipelines("my pipeline", %User{id: 123})
      [%Pipeline{slug: "my pipeline"}, ...]

  """
  @spec list_pipelines(User.t()) :: [Pipeline.t()]
  @spec list_pipelines(search :: String.t() | nil, User.t()) :: [Pipeline.t()]
  def list_pipelines(search \\ nil, user)

  def list_pipelines(search, %{id: user_id}) when search |> is_nil() or search == "" do
    Repo.all(from p in Pipeline, where: p.user_id == ^user_id, order_by: p.slug)
  end

  def list_pipelines(search, %{id: user_id}) when search |> is_binary() do
    trimmed_search = String.trim(search)

    Repo.all(
      from p in Pipeline,
        where: p.user_id == ^user_id,
        where:
          fragment(
            "search @@ to_tsquery(websearch_to_tsquery(?)::text || ':*')",
            ^trimmed_search
          ),
        order_by: {
          :desc,
          fragment(
            "ts_rank_cd(search, to_tsquery(websearch_to_tsquery(?)::text || ':*'), 4)",
            ^trimmed_search
          )
        }
    )
  end

  @doc """
  Returns the list of public pipelines for viewing

  ## Examples

      iex> list_public_pipelines()
      [%Pipeline{}, ...]

      iex> list_public_pipelines("my pipeline")
      [%Pipeline{slug: "my pipeline"}, ...]
  """
  @spec list_public_pipelines() :: [Pipeline.t()]
  @spec list_public_pipelines(search :: String.t() | nil) :: [Pipeline.t()]
  def list_public_pipelines(search \\ nil)

  def list_public_pipelines(search) when search |> is_nil() or search == "" do
    Repo.all(from p in Pipeline, where: p.visibility == :public, order_by: p.slug)
  end

  def list_public_pipelines(search) when search |> is_binary() do
    trimmed_search = String.trim(search)

    Repo.all(
      from p in Pipeline,
        where: p.visibility == :public,
        where:
          fragment(
            "search @@ to_tsquery(websearch_to_tsquery(?)::text || ':*')",
            ^trimmed_search
          ),
        order_by: {
          :desc,
          fragment(
            "ts_rank_cd(search, to_tsquery(websearch_to_tsquery(?)::text || ':*'), 4)",
            ^trimmed_search
          )
        }
    )
  end

  @doc """
  Gets a single pipeline.

  Raises `Ecto.NoResultsError` if the Pipeline does not exist.

  ## Examples

      iex> get_pipeline!(123, %User{id: 123})
      %Pipeline{}

      iex> get_pipeline!(456, %User{id: 123})
      ** (Ecto.NoResultsError)

  """
  @spec get_pipeline!(Pipeline.id(), User.t()) :: Pipeline.t()
  def get_pipeline!(id, %{id: user_id}) do
    Repo.one!(
      from p in Pipeline,
        where: p.id == ^id,
        where: p.user_id == ^user_id or p.visibility in [:public, :unlisted]
    )
  end

  def get_pipeline!(id, _invalid_user) do
    Repo.one!(
      from p in Pipeline,
        where: p.id == ^id,
        where: p.visibility in [:public, :unlisted]
    )
  end

  @doc """
  Gets a single pipeline by it's slug.

  Raises `Ecto.NoResultsError` if the Pipeline does not exist.

  ## Examples

      iex> get_pipeline_by_slug("my-pipeline", %User{id: 123})
      %Pipeline{}

      iex> get_pipeline_by_slug("my-pipeline", %User{id: 123})
      ** (Ecto.NoResultsError)

  """
  @spec get_pipeline_by_slug(Pipeline.slug(), User.t()) :: Pipeline.t() | nil
  def get_pipeline_by_slug(slug, %{id: user_id}) do
    Repo.one(
      from p in Pipeline,
        where: p.slug == ^slug,
        where: p.user_id == ^user_id or p.visibility in [:public, :unlisted]
    )
  end

  def get_pipeline_by_slug(slug, _invalid_user) do
    Repo.one(
      from p in Pipeline,
        where: p.slug == ^slug,
        where: p.visibility in [:public, :unlisted]
    )
  end

  @doc """
  Creates a pipeline.

  ## Examples

      iex> create_pipeline(%{field: value}, %User{id: 123})
      {:ok, %Pipeline{}}

      iex> create_pipeline(%{field: bad_value}, %User{id: 123})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_pipeline(User.t()) :: {:ok, Pipeline.t()} | {:error, Pipeline.changeset()}
  @spec create_pipeline(attrs :: map(), User.t()) ::
          {:ok, Pipeline.t()} | {:error, Pipeline.changeset()}
  def create_pipeline(attrs \\ %{}, user) do
    Pipeline.create_changeset(attrs, user) |> Repo.insert()
  end

  @doc """
  Updates a pipeline.

  ## Examples

      iex> update_pipeline(pipeline, %{field: new_value}, %User{id: 123})
      {:ok, %Pipeline{}}

      iex> update_pipeline(pipeline, %{field: bad_value}, %User{id: 123})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_pipeline(Pipeline.t(), attrs :: map(), User.t()) ::
          {:ok, Pipeline.t()} | {:error, Pipeline.changeset()}
  def update_pipeline(%Pipeline{} = pipeline, attrs, user) do
    pipeline
    |> Pipeline.update_changeset(attrs, user)
    |> Repo.update()
  end

  @doc """
  Deletes a pipeline.

  ## Examples

      iex> delete_pipeline(%Pipeline{user_id: 123}, %User{id: 123})
      {:ok, %Pipeline{}}

      iex> delete_pipeline(%Pipeline{}, %User{role: :admin})
      {:ok, %Pipeline{}}

      iex> delete_pipeline(%Pipeline{}, %User{id: 123})
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_pipeline(Pipeline.t(), User.t()) ::
          {:ok, Pipeline.t()} | {:error, Pipeline.changeset()}
  def delete_pipeline(%Pipeline{user_id: user_id} = pipeline, %{id: user_id}) do
    pipeline |> Repo.delete()
  end

  def delete_pipeline(%Pipeline{} = pipeline, %{role: :admin}) do
    pipeline |> Repo.delete()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking pipeline changes.

  ## Examples

      iex> change_pipeline(pipeline, %User{id: 123})
      %Ecto.Changeset{data: %Pipeline{}}

      iex> change_pipeline(pipeline, %{slug: "new slug"}, %User{id: 123})
      %Ecto.Changeset{data: %Pipeline{}}

  """
  @spec change_pipeline(Pipeline.t(), User.t()) :: Pipeline.changeset()
  @spec change_pipeline(Pipeline.t(), attrs :: map(), User.t()) :: Pipeline.changeset()
  def change_pipeline(%Pipeline{} = pipeline, attrs \\ %{}, user) do
    pipeline |> Pipeline.update_changeset(attrs, user)
  end

  @doc """
  Gets a canonical string representation of the `:tags` field for a Pipeline
  """
  @spec get_tags_string(Pipeline.t() | Pipeline.changeset() | [String.t()] | nil) :: String.t()
  def get_tags_string(nil), do: ""
  def get_tags_string(tags) when tags |> is_list(), do: tags |> Enum.join(",")
  def get_tags_string(%Pipeline{tags: tags}), do: tags |> get_tags_string()

  def get_tags_string(%Changeset{} = changeset) do
    changeset
    |> Changeset.get_field(:tags)
    |> get_tags_string()
  end
end
