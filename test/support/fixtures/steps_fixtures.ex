defmodule Memex.StepsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Memex.Steps` context.
  """
  alias Memex.Pipelines.Steps

  @doc """
  Generate a step.
  """
  def step_fixture(attrs \\ %{}, position, pipeline, user) do
    {:ok, step} =
      attrs
      |> Enum.into(%{
        content: "some content",
        title: "some title"
      })
      |> Steps.create_step(position, pipeline, user)

    step
  end
end
