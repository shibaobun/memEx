defmodule Memex.ContextsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Memex.Contexts` context.
  """
  import Memex.Fixtures
  alias Memex.{Accounts.User, Contexts, Contexts.Context}

  @doc """
  Generate a context.
  """
  @spec context_fixture(User.t()) :: Context.t()
  @spec context_fixture(attrs :: map(), User.t()) :: Context.t()
  def context_fixture(attrs \\ %{}, user) do
    {:ok, context} =
      attrs
      |> Enum.into(%{
        content: "some content",
        tag: [],
        slug: random_slug(),
        visibility: :private
      })
      |> Contexts.create_context(user)

    context
  end
end
