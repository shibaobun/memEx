defmodule Memex.StepsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Memex.Steps` context.
  """

  @doc """
  Generate a step.
  """
  def step_fixture(attrs \\ %{}) do
    {:ok, step} =
      attrs
      |> Enum.into(%{
        description: "some description",
        position: 42,
        title: "some title"
      })
      |> Memex.Steps.create_step()

    step
  end
end
