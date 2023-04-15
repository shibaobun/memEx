defmodule MemexWeb.NoteLiveTest do
  use MemexWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  import Memex.Fixtures

  @create_attrs %{
    content: "some content",
    tags_string: "tag1",
    slug: "some-slug",
    visibility: :public
  }
  @update_attrs %{
    content: "some updated content",
    tags_string: "tag1,tag2",
    slug: "some-updated-slug",
    visibility: :private
  }
  @invalid_attrs %{
    content: nil,
    tags_string: "invalid tags",
    slug: nil,
    visibility: nil
  }

  defp create_note(%{current_user: current_user}) do
    [note: note_fixture(current_user)]
  end

  describe "Index" do
    setup [:register_and_log_in_user, :create_note]

    test "lists all notes", %{conn: conn, note: note} do
      {:ok, _index_live, html} = live(conn, ~p"/notes")

      assert html =~ "notes"
      assert html =~ note.slug
    end

    test "searches by tag", %{conn: conn, note: %{tags: [tag]}} do
      {:ok, index_live, html} = live(conn, ~p"/notes")

      assert html =~ tag
      assert index_live |> element("a", tag) |> render_click()
      assert_patch(index_live, ~p"/notes/#{tag}")
    end

    test "saves new note", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/notes")
      assert index_live |> element("a", "new note") |> render_click() =~ "new note"
      assert_patch(index_live, ~p"/notes/new")

      html =
        index_live
        |> form("#note-form")
        |> render_change(note: @invalid_attrs)

      assert html =~ "can&#39;t be blank"
      assert html =~ "tags must be comma-delimited"

      {:ok, _live, html} =
        index_live
        |> form("#note-form")
        |> render_submit(note: @create_attrs)
        |> follow_redirect(conn, ~p"/notes")

      assert html =~ "#{@create_attrs.slug} created"
      assert html =~ @create_attrs.slug
    end

    test "updates note in listing", %{conn: conn, note: note} do
      {:ok, index_live, _html} = live(conn, ~p"/notes")

      assert index_live |> element(~s/a[aria-label="edit #{note.slug}"]/) |> render_click() =~
               "edit"

      assert_patch(index_live, ~p"/notes/#{note}/edit")

      assert index_live
             |> form("#note-form")
             |> render_change(note: @invalid_attrs) =~ "can&#39;t be blank"

      {:ok, _live, html} =
        index_live
        |> form("#note-form")
        |> render_submit(note: @update_attrs)
        |> follow_redirect(conn, ~p"/notes")

      assert html =~ "#{@update_attrs.slug} saved"
      assert html =~ @update_attrs.slug
    end

    test "deletes note in listing", %{conn: conn, note: note} do
      {:ok, index_live, _html} = live(conn, ~p"/notes")

      assert index_live |> element(~s/a[aria-label="delete #{note.slug}"]/) |> render_click()
      refute has_element?(index_live, "#note-#{note.id}")
    end
  end

  describe "show" do
    setup [:register_and_log_in_user, :create_note]

    test "displays note", %{conn: conn, note: note} do
      {:ok, _show_live, html} = live(conn, ~p"/note/#{note}")

      assert html =~ "note"
      assert html =~ note.slug
    end

    test "updates note within modal", %{conn: conn, note: note} do
      {:ok, show_live, _html} = live(conn, ~p"/note/#{note}")
      assert show_live |> element("a", "edit") |> render_click() =~ "edit"
      assert_patch(show_live, ~p"/note/#{note}/edit")

      assert show_live
             |> form("#note-form")
             |> render_change(note: @invalid_attrs) =~ "can&#39;t be blank"

      {:ok, _live, html} =
        show_live
        |> form("#note-form")
        |> render_submit(note: @update_attrs |> Map.put(:slug, note.slug))
        |> follow_redirect(conn, ~p"/note/#{note}")

      assert html =~ "#{note.slug} saved"
      assert html =~ note.slug
    end

    test "deletes note", %{conn: conn, note: note} do
      {:ok, show_live, _html} = live(conn, ~p"/note/#{note}")

      {:ok, index_live, _html} =
        show_live
        |> element(~s/button[aria-label="delete #{note.slug}"]/)
        |> render_click()
        |> follow_redirect(conn, ~p"/notes")

      refute has_element?(index_live, "#note-#{note.id}")
    end
  end

  describe "show with note" do
    setup [:register_and_log_in_user]

    setup %{current_user: current_user} do
      %{slug: note_slug} = note = note_fixture(current_user)

      [
        note: note,
        backlinked_note:
          note_fixture(%{content: "example with backlink to [[#{note_slug}]] note"}, current_user)
      ]
    end

    test "searches by tag", %{conn: conn, note: %{tags: [tag]} = note} do
      {:ok, show_live, html} = live(conn, ~p"/note/#{note}")

      assert html =~ tag
      assert show_live |> element("a", tag) |> render_click()
      assert_redirect(show_live, ~p"/notes/#{tag}")
    end

    test "displays context", %{
      conn: conn,
      backlinked_note: %{slug: backlinked_note_slug},
      note: %{slug: note_slug}
    } do
      {:ok, show_live, html} = live(conn, ~p"/note/#{backlinked_note_slug}")

      assert html =~ "context"
      assert html =~ ~p"/note/#{note_slug}"
      assert has_element?(show_live, "a", note_slug)
    end
  end
end
