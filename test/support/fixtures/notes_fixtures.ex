defmodule Memex.NotesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Memex.Notes` context.
  """

  @doc """
  Generate a note.
  """
  def note_fixture(attrs \\ %{}) do
    {:ok, note} =
      attrs
      |> Enum.into(%{
        content: "some content",
        tag: [],
        title: "some title",
        visibility: :public
      })
      |> Memex.Notes.create_note()

    note
  end
end
