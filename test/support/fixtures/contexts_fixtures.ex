defmodule Memex.ContextsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Memex.Contexts` context.
  """

  @doc """
  Generate a context.
  """
  def context_fixture(attrs \\ %{}) do
    {:ok, context} =
      attrs
      |> Enum.into(%{
        content: "some content",
        tag: [],
        title: "some title",
        visibility: :public
      })
      |> Memex.Contexts.create_context()

    context
  end
end
