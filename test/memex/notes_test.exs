defmodule Memex.NotesTest do
  use Memex.DataCase

  alias Memex.Notes

  describe "notes" do
    alias Memex.Notes.Note

    import Memex.NotesFixtures

    @invalid_attrs %{content: nil, tag: nil, title: nil, visibility: nil}

    test "list_notes/0 returns all notes" do
      note = note_fixture()
      assert Notes.list_notes() == [note]
    end

    test "get_note!/1 returns the note with given id" do
      note = note_fixture()
      assert Notes.get_note!(note.id) == note
    end

    test "create_note/1 with valid data creates a note" do
      valid_attrs = %{content: "some content", tag: [], title: "some title", visibility: :public}

      assert {:ok, %Note{} = note} = Notes.create_note(valid_attrs)
      assert note.content == "some content"
      assert note.tag == []
      assert note.title == "some title"
      assert note.visibility == :public
    end

    test "create_note/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Notes.create_note(@invalid_attrs)
    end

    test "update_note/2 with valid data updates the note" do
      note = note_fixture()

      update_attrs = %{
        content: "some updated content",
        tag: [],
        title: "some updated title",
        visibility: :private
      }

      assert {:ok, %Note{} = note} = Notes.update_note(note, update_attrs)
      assert note.content == "some updated content"
      assert note.tag == []
      assert note.title == "some updated title"
      assert note.visibility == :private
    end

    test "update_note/2 with invalid data returns error changeset" do
      note = note_fixture()
      assert {:error, %Ecto.Changeset{}} = Notes.update_note(note, @invalid_attrs)
      assert note == Notes.get_note!(note.id)
    end

    test "delete_note/1 deletes the note" do
      note = note_fixture()
      assert {:ok, %Note{}} = Notes.delete_note(note)
      assert_raise Ecto.NoResultsError, fn -> Notes.get_note!(note.id) end
    end

    test "change_note/1 returns a note changeset" do
      note = note_fixture()
      assert %Ecto.Changeset{} = Notes.change_note(note)
    end
  end
end
