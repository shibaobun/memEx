defmodule Memex.NotesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Memex.Notes` context.
  """
  import Memex.Fixtures
  alias Memex.{Accounts.User, Notes, Notes.Note}

  @doc """
  Generate a note.
  """
  @spec note_fixture(User.t()) :: Note.t()
  @spec note_fixture(attrs :: map(), User.t()) :: Note.t()
  def note_fixture(attrs \\ %{}, user) do
    {:ok, note} =
      attrs
      |> Enum.into(%{
        content: "some content",
        tag: [],
        slug: random_slug(),
        visibility: :private
      })
      |> Notes.create_note(user)

    note
  end
end
