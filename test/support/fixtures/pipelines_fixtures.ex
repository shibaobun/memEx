defmodule Memex.PipelinesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Memex.Pipelines` context.
  """
  import Memex.Fixtures
  alias Memex.{Accounts.User, Pipelines, Pipelines.Pipeline}

  @doc """
  Generate a pipeline.
  """
  @spec pipeline_fixture(User.t()) :: Pipeline.t()
  @spec pipeline_fixture(attrs :: map(), User.t()) :: Pipeline.t()
  def pipeline_fixture(attrs \\ %{}, user) do
    {:ok, pipeline} =
      attrs
      |> Enum.into(%{
        description: "some description",
        tags: [],
        slug: random_slug(),
        visibility: :private
      })
      |> Pipelines.create_pipeline(user)

    pipeline
  end
end
