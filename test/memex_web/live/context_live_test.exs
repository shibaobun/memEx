defmodule MemexWeb.ContextLiveTest do
  use MemexWeb.ConnCase

  import Phoenix.LiveViewTest
  import Memex.ContextsFixtures

  @create_attrs %{content: "some content", tag: [], title: "some title", visibility: :public}
  @update_attrs %{
    content: "some updated content",
    tag: [],
    title: "some updated title",
    visibility: :private
  }
  @invalid_attrs %{content: nil, tag: [], title: nil, visibility: nil}

  defp create_context(_) do
    context = context_fixture()
    %{context: context}
  end

  describe "Index" do
    setup [:create_context]

    test "lists all contexts", %{conn: conn, context: context} do
      {:ok, _index_live, html} = live(conn, Routes.context_index_path(conn, :index))

      assert html =~ "listing contexts"
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

      assert html =~ "context created successfully"
      assert html =~ "some content"
    end

    test "updates context in listing", %{conn: conn, context: context} do
      {:ok, index_live, _html} = live(conn, Routes.context_index_path(conn, :index))

      assert index_live |> element("#context-#{context.id} a", "edit") |> render_click() =~
               "edit context"

      assert_patch(index_live, Routes.context_index_path(conn, :edit, context))

      assert index_live
             |> form("#context-form", context: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#context-form", context: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.context_index_path(conn, :index))

      assert html =~ "context updated successfully"
      assert html =~ "some updated content"
    end

    test "deletes context in listing", %{conn: conn, context: context} do
      {:ok, index_live, _html} = live(conn, Routes.context_index_path(conn, :index))

      assert index_live |> element("#context-#{context.id} a", "delete") |> render_click()
      refute has_element?(index_live, "#context-#{context.id}")
    end
  end

  describe "show" do
    setup [:create_context]

    test "displays context", %{conn: conn, context: context} do
      {:ok, _show_live, html} = live(conn, Routes.context_show_path(conn, :show, context))

      assert html =~ "show context"
      assert html =~ context.content
    end

    test "updates context within modal", %{conn: conn, context: context} do
      {:ok, show_live, _html} = live(conn, Routes.context_show_path(conn, :show, context))

      assert show_live |> element("a", "edit") |> render_click() =~
               "edit context"

      assert_patch(show_live, Routes.context_show_path(conn, :edit, context))

      assert show_live
             |> form("#context-form", context: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        show_live
        |> form("#context-form", context: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.context_show_path(conn, :show, context))

      assert html =~ "context updated successfully"
      assert html =~ "some updated content"
    end
  end
end
