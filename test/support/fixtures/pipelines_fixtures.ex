defmodule Memex.PipelinesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Memex.Pipelines` context.
  """

  @doc """
  Generate a pipeline.
  """
  def pipeline_fixture(attrs \\ %{}) do
    {:ok, pipeline} =
      attrs
      |> Enum.into(%{
        description: "some description",
        title: "some title",
        visibility: :public
      })
      |> Memex.Pipelines.create_pipeline()

    pipeline
  end
end
