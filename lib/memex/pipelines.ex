defmodule Memex.Pipelines do
  @moduledoc """
  The Pipelines context.
  """

  import Ecto.Query, warn: false
  alias Memex.Repo

  alias Memex.Pipelines.Pipeline

  @doc """
  Returns the list of pipelines.

  ## Examples

      iex> list_pipelines()
      [%Pipeline{}, ...]

  """
  def list_pipelines do
    Repo.all(Pipeline)
  end

  @doc """
  Gets a single pipeline.

  Raises `Ecto.NoResultsError` if the Pipeline does not exist.

  ## Examples

      iex> get_pipeline!(123)
      %Pipeline{}

      iex> get_pipeline!(456)
      ** (Ecto.NoResultsError)

  """
  def get_pipeline!(id), do: Repo.get!(Pipeline, id)

  @doc """
  Creates a pipeline.

  ## Examples

      iex> create_pipeline(%{field: value})
      {:ok, %Pipeline{}}

      iex> create_pipeline(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_pipeline(attrs \\ %{}) do
    %Pipeline{}
    |> Pipeline.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a pipeline.

  ## Examples

      iex> update_pipeline(pipeline, %{field: new_value})
      {:ok, %Pipeline{}}

      iex> update_pipeline(pipeline, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_pipeline(%Pipeline{} = pipeline, attrs) do
    pipeline
    |> Pipeline.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a pipeline.

  ## Examples

      iex> delete_pipeline(pipeline)
      {:ok, %Pipeline{}}

      iex> delete_pipeline(pipeline)
      {:error, %Ecto.Changeset{}}

  """
  def delete_pipeline(%Pipeline{} = pipeline) do
    Repo.delete(pipeline)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking pipeline changes.

  ## Examples

      iex> change_pipeline(pipeline)
      %Ecto.Changeset{data: %Pipeline{}}

  """
  def change_pipeline(%Pipeline{} = pipeline, attrs \\ %{}) do
    Pipeline.changeset(pipeline, attrs)
  end
end
