defmodule Memex.NotesTest do
  use Memex.DataCase
  import Memex.NotesFixtures
  alias Memex.{Notes, Notes.Note}
  @moduletag :notes_test
  @invalid_attrs %{content: nil, tag: nil, slug: nil, visibility: nil}

  describe "notes" do
    setup do
      [user: user_fixture()]
    end

    test "list_notes/1 returns all notes for a user", %{user: user} do
      note_a = note_fixture(%{slug: "a", visibility: :public}, user)
      note_b = note_fixture(%{slug: "b", visibility: :unlisted}, user)
      note_c = note_fixture(%{slug: "c", visibility: :private}, user)
      _shouldnt_return = note_fixture(%{visibility: :private}, user_fixture())

      assert Notes.list_notes(user) == [note_a, note_b, note_c]
    end

    test "list_notes/2 returns relevant notes for a user", %{user: user} do
      note_a = note_fixture(%{slug: "dogs", content: "has some treats in it"}, user)
      note_b = note_fixture(%{slug: "cats", tags: ["home"]}, user)

      note_c =
        %{slug: "chickens", content: "bananas stuff", tags: ["life", "decisions"]}
        |> note_fixture(user)

      _shouldnt_return =
        %{slug: "dog", content: "banana treat stuff", visibility: :private}
        |> note_fixture(user_fixture())

      # slug
      assert Notes.list_notes("dog", user) == [note_a]
      assert Notes.list_notes("dogs", user) == [note_a]
      assert Notes.list_notes("cat", user) == [note_b]
      assert Notes.list_notes("chicken", user) == [note_c]

      # content
      assert Notes.list_notes("treat", user) == [note_a]
      assert Notes.list_notes("banana", user) == [note_c]
      assert Notes.list_notes("stuff", user) == [note_c]

      # tag
      assert Notes.list_notes("home", user) == [note_b]
      assert Notes.list_notes("life", user) == [note_c]
      assert Notes.list_notes("decision", user) == [note_c]
      assert Notes.list_notes("decisions", user) == [note_c]
    end

    test "list_public_notes/0 returns public notes", %{user: user} do
      public_note = note_fixture(%{visibility: :public}, user)
      note_fixture(%{visibility: :unlisted}, user)
      note_fixture(%{visibility: :private}, user)
      assert Notes.list_public_notes() == [public_note]
    end

    test "list_public_notes/1 returns relevant notes for a user", %{user: user} do
      note_a =
        %{slug: "dogs", content: "has some treats in it", visibility: :public}
        |> note_fixture(user)

      note_b =
        %{slug: "cats", tags: ["home"], visibility: :public}
        |> note_fixture(user)

      note_c =
        %{
          slug: "chickens",
          content: "bananas stuff",
          tags: ["life", "decisions"],
          visibility: :public
        }
        |> note_fixture(user)

      _shouldnt_return =
        %{
          slug: "dog",
          content: "treats bananas stuff",
          tags: ["home", "life", "decisions"],
          visibility: :private
        }
        |> note_fixture(user)

      # slug
      assert Notes.list_public_notes("dog") == [note_a]
      assert Notes.list_public_notes("dogs") == [note_a]
      assert Notes.list_public_notes("cat") == [note_b]
      assert Notes.list_public_notes("chicken") == [note_c]

      # content
      assert Notes.list_public_notes("treat") == [note_a]
      assert Notes.list_public_notes("banana") == [note_c]
      assert Notes.list_public_notes("stuff") == [note_c]

      # tag
      assert Notes.list_public_notes("home") == [note_b]
      assert Notes.list_public_notes("life") == [note_c]
      assert Notes.list_public_notes("decision") == [note_c]
      assert Notes.list_public_notes("decisions") == [note_c]
    end

    test "get_note!/1 returns the note with given id", %{user: user} do
      note = note_fixture(%{visibility: :public}, user)
      assert Notes.get_note!(note.id, user) == note

      note = note_fixture(%{visibility: :unlisted}, user)
      assert Notes.get_note!(note.id, user) == note

      note = note_fixture(%{visibility: :private}, user)
      assert Notes.get_note!(note.id, user) == note
    end

    test "get_note!/1 only returns unlisted or public notes for other users", %{user: user} do
      another_user = user_fixture()
      note = note_fixture(%{visibility: :public}, another_user)
      assert Notes.get_note!(note.id, user) == note

      note = note_fixture(%{visibility: :unlisted}, another_user)
      assert Notes.get_note!(note.id, user) == note

      note = note_fixture(%{visibility: :private}, another_user)

      assert_raise Ecto.NoResultsError, fn ->
        Notes.get_note!(note.id, user)
      end
    end

    test "get_note_by_slug/1 returns the note with given id", %{user: user} do
      note = note_fixture(%{slug: "a", visibility: :public}, user)
      assert Notes.get_note_by_slug("a", user) == note

      note = note_fixture(%{slug: "b", visibility: :unlisted}, user)
      assert Notes.get_note_by_slug("b", user) == note

      note = note_fixture(%{slug: "c", visibility: :private}, user)
      assert Notes.get_note_by_slug("c", user) == note
    end

    test "get_note_by_slug/1 only returns unlisted or public notes for other users", %{
      user: user
    } do
      another_user = user_fixture()
      note = note_fixture(%{slug: "a", visibility: :public}, another_user)
      assert Notes.get_note_by_slug("a", user) == note

      note = note_fixture(%{slug: "b", visibility: :unlisted}, another_user)
      assert Notes.get_note_by_slug("b", user) == note

      note_fixture(%{slug: "c", visibility: :private}, another_user)
      assert Notes.get_note_by_slug("c", user) |> is_nil()
    end

    test "create_note/1 with valid data creates a note", %{user: user} do
      valid_attrs = %{
        "content" => "some content",
        "tags_string" => "tag1,tag2",
        "slug" => "some-slug",
        "visibility" => :public
      }

      assert {:ok, %Note{} = note} = Notes.create_note(valid_attrs, user)
      assert note.content == "some content"
      assert note.tags == ["tag1", "tag2"]
      assert note.slug == "some-slug"
      assert note.visibility == :public
    end

    test "create_note/1 with invalid data returns error changeset", %{user: user} do
      assert {:error, %Ecto.Changeset{}} = Notes.create_note(@invalid_attrs, user)
    end

    test "update_note/2 with valid data updates the note", %{user: user} do
      note = note_fixture(user)

      update_attrs = %{
        "content" => "some updated content",
        "tags_string" => "tag1,tag2",
        "slug" => "some-updated-slug",
        "visibility" => :private
      }

      assert {:ok, %Note{} = note} = Notes.update_note(note, update_attrs, user)
      assert note.content == "some updated content"
      assert note.tags == ["tag1", "tag2"]
      assert note.slug == "some-updated-slug"
      assert note.visibility == :private
    end

    test "update_note/2 with invalid data returns error changeset", %{user: user} do
      note = note_fixture(user)
      assert {:error, %Ecto.Changeset{}} = Notes.update_note(note, @invalid_attrs, user)
      assert note == Notes.get_note!(note.id, user)
    end

    test "delete_note/1 deletes the note", %{user: user} do
      note = note_fixture(user)
      assert {:ok, %Note{}} = Notes.delete_note(note, user)
      assert_raise Ecto.NoResultsError, fn -> Notes.get_note!(note.id, user) end
    end

    test "delete_note/1 deletes the note for an admin user", %{user: user} do
      admin_user = admin_fixture()
      note = note_fixture(user)
      assert {:ok, %Note{}} = Notes.delete_note(note, admin_user)
      assert_raise Ecto.NoResultsError, fn -> Notes.get_note!(note.id, user) end
    end

    test "change_note/1 returns a note changeset", %{user: user} do
      note = note_fixture(user)
      assert %Ecto.Changeset{} = Notes.change_note(note, user)
    end
  end
end
