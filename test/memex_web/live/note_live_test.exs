defmodule MemexWeb.NoteLiveTest do
  use MemexWeb.ConnCase

  import Phoenix.LiveViewTest
  import Memex.NotesFixtures

  @create_attrs %{
    "content" => "some content",
    "tags_string" => "tag1",
    "title" => "some title",
    "visibility" => :public
  }
  @update_attrs %{
    "content" => "some updated content",
    "tags_string" => "tag1,tag2",
    "title" => "some updated title",
    "visibility" => :private
  }
  @invalid_attrs %{
    "content" => nil,
    "tags_string" => "",
    "title" => nil,
    "visibility" => nil
  }

  defp create_note(%{user: user}) do
    [note: note_fixture(user)]
  end

  describe "Index" do
    setup [:register_and_log_in_user, :create_note]

    test "lists all notes", %{conn: conn, note: note} do
      {:ok, _index_live, html} = live(conn, Routes.note_index_path(conn, :index))

      assert html =~ "notes"
      assert html =~ note.content
    end

    test "saves new note", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, Routes.note_index_path(conn, :index))

      assert index_live |> element("a", "new note") |> render_click() =~
               "new note"

      assert_patch(index_live, Routes.note_index_path(conn, :new))

      assert index_live
             |> form("#note-form", note: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#note-form", note: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.note_index_path(conn, :index))

      assert html =~ "#{@create_attrs |> Map.get("title")} created"
      assert html =~ "some content"
    end

    test "updates note in listing", %{conn: conn, note: note} do
      {:ok, index_live, _html} = live(conn, Routes.note_index_path(conn, :index))

      assert index_live |> element("[data-qa=\"note-edit-#{note.id}\"]") |> render_click() =~
               "edit"

      assert_patch(index_live, Routes.note_index_path(conn, :edit, note))

      assert index_live
             |> form("#note-form", note: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#note-form", note: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.note_index_path(conn, :index))

      assert html =~ "#{@update_attrs |> Map.get("title")} saved"
      assert html =~ "some updated content"
    end

    test "deletes note in listing", %{conn: conn, note: note} do
      {:ok, index_live, _html} = live(conn, Routes.note_index_path(conn, :index))

      assert index_live |> element("[data-qa=\"delete-note-#{note.id}\"]") |> render_click()
      refute has_element?(index_live, "#note-#{note.id}")
    end
  end

  describe "show" do
    setup [:register_and_log_in_user, :create_note]

    test "displays note", %{conn: conn, note: note} do
      {:ok, _show_live, html} = live(conn, Routes.note_show_path(conn, :show, note))

      assert html =~ "show note"
      assert html =~ note.content
    end

    test "updates note within modal", %{conn: conn, note: note} do
      {:ok, show_live, _html} = live(conn, Routes.note_show_path(conn, :show, note))

      assert show_live |> element("a", "edit") |> render_click() =~ "edit"

      assert_patch(show_live, Routes.note_show_path(conn, :edit, note))

      assert show_live
             |> form("#note-form", note: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        show_live
        |> form("#note-form", note: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.note_show_path(conn, :show, note))

      assert html =~ "#{@update_attrs |> Map.get("title")} saved"
      assert html =~ "some updated content"
    end

    test "deletes note", %{conn: conn, note: note} do
      {:ok, show_live, _html} = live(conn, Routes.note_show_path(conn, :show, note))

      {:ok, index_live, _html} =
        show_live
        |> element("[data-qa=\"delete-note-#{note.id}\"]")
        |> render_click()
        |> follow_redirect(conn, Routes.note_index_path(conn, :index))

      refute has_element?(index_live, "#note-#{note.id}")
    end
  end
end
