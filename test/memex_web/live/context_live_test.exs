defmodule MemexWeb.ContextLiveTest do
  use MemexWeb.ConnCase

  import Phoenix.LiveViewTest
  import Memex.ContextsFixtures

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

  defp create_context(%{user: user}) do
    [context: context_fixture(user)]
  end

  describe "Index" do
    setup [:register_and_log_in_user, :create_context]

    test "lists all contexts", %{conn: conn, context: context} do
      {:ok, _index_live, html} = live(conn, Routes.context_index_path(conn, :index))

      assert html =~ "contexts"
      assert html =~ context.content
    end

    test "saves new context", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, Routes.context_index_path(conn, :index))

      assert index_live |> element("a", "new context") |> render_click() =~
               "new context"

      assert_patch(index_live, Routes.context_index_path(conn, :new))

      assert index_live
             |> form("#context-form", context: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#context-form", context: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.context_index_path(conn, :index))

      assert html =~ "#{@create_attrs |> Map.get("title")} created"
      assert html =~ "some content"
    end

    test "updates context in listing", %{conn: conn, context: context} do
      {:ok, index_live, _html} = live(conn, Routes.context_index_path(conn, :index))

      assert index_live |> element("[data-qa=\"context-edit-#{context.id}\"]") |> render_click() =~
               "edit"

      assert_patch(index_live, Routes.context_index_path(conn, :edit, context))

      assert index_live
             |> form("#context-form", context: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#context-form", context: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.context_index_path(conn, :index))

      assert html =~ "#{@update_attrs |> Map.get("title")} saved"
      assert html =~ "some updated content"
    end

    test "deletes context in listing", %{conn: conn, context: context} do
      {:ok, index_live, _html} = live(conn, Routes.context_index_path(conn, :index))

      assert index_live |> element("[data-qa=\"delete-context-#{context.id}\"]") |> render_click()
      refute has_element?(index_live, "#context-#{context.id}")
    end
  end

  describe "show" do
    setup [:register_and_log_in_user, :create_context]

    test "displays context", %{conn: conn, context: context} do
      {:ok, _show_live, html} = live(conn, Routes.context_show_path(conn, :show, context))

      assert html =~ "context"
      assert html =~ context.content
    end

    test "updates context within modal", %{conn: conn, context: context} do
      {:ok, show_live, _html} = live(conn, Routes.context_show_path(conn, :show, context))

      assert show_live |> element("a", "edit") |> render_click() =~ "edit"

      assert_patch(show_live, Routes.context_show_path(conn, :edit, context))

      assert show_live
             |> form("#context-form", context: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        show_live
        |> form("#context-form", context: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.context_show_path(conn, :show, context))

      assert html =~ "#{@update_attrs |> Map.get("title")} saved"
      assert html =~ "some updated content"
    end

    test "deletes context", %{conn: conn, context: context} do
      {:ok, show_live, _html} = live(conn, Routes.context_show_path(conn, :show, context))

      {:ok, index_live, _html} =
        show_live
        |> element("[data-qa=\"delete-context-#{context.id}\"]")
        |> render_click()
        |> follow_redirect(conn, Routes.context_index_path(conn, :index))

      refute has_element?(index_live, "#context-#{context.id}")
    end
  end
end
