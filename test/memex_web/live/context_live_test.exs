defmodule MemexWeb.ContextLiveTest do
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
    tags_string: "invalid_tag or_tags",
    slug: nil,
    visibility: nil
  }

  defp create_context(%{current_user: current_user}) do
    [context: context_fixture(current_user)]
  end

  describe "Index" do
    setup [:register_and_log_in_user, :create_context]

    test "lists all contexts", %{conn: conn, context: context} do
      {:ok, _index_live, html} = live(conn, ~p"/contexts")

      assert html =~ "contexts"
      assert html =~ context.slug
    end

    test "searches by tag", %{conn: conn, context: %{tags: [tag]}} do
      {:ok, index_live, html} = live(conn, ~p"/contexts")

      assert html =~ tag
      assert index_live |> element("a", tag) |> render_click()
      assert_patch(index_live, ~p"/contexts/#{tag}")
    end

    test "saves new context", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/contexts")
      assert index_live |> element("a", "new context") |> render_click() =~ "new context"
      assert_patch(index_live, ~p"/contexts/new")

      assert index_live
             |> form("#context-form")
             |> render_change(context: @invalid_attrs) =~ "can&#39;t be blank"

      {:ok, _live, html} =
        index_live
        |> form("#context-form")
        |> render_submit(context: @create_attrs)
        |> follow_redirect(conn, ~p"/contexts")

      assert html =~ "#{@create_attrs.slug} created"
      assert html =~ @create_attrs.slug
    end

    test "updates context in listing", %{conn: conn, context: context} do
      {:ok, index_live, _html} = live(conn, ~p"/contexts")

      assert index_live |> element(~s/a[aria-label="edit #{context.slug}"]/) |> render_click() =~
               "edit"

      assert_patch(index_live, ~p"/contexts/#{context}/edit")

      assert index_live
             |> form("#context-form")
             |> render_change(context: @invalid_attrs) =~ "can&#39;t be blank"

      {:ok, _live, html} =
        index_live
        |> form("#context-form")
        |> render_submit(context: @update_attrs)
        |> follow_redirect(conn, ~p"/contexts")

      assert html =~ "#{@update_attrs.slug} saved"
      assert html =~ "some-updated-slug"
    end

    test "deletes context in listing", %{conn: conn, context: context} do
      {:ok, index_live, _html} = live(conn, ~p"/contexts")

      assert index_live |> element(~s/a[aria-label="delete #{context.slug}"]/) |> render_click()
      refute has_element?(index_live, "#context-#{context.id}")
    end
  end

  describe "show" do
    setup [:register_and_log_in_user, :create_context]

    test "displays context", %{conn: conn, context: context} do
      {:ok, _show_live, html} = live(conn, ~p"/context/#{context}")

      assert html =~ "context"
      assert html =~ context.slug
    end

    test "updates context within modal", %{conn: conn, context: context} do
      {:ok, show_live, _html} = live(conn, ~p"/context/#{context}")
      assert show_live |> element("a", "edit") |> render_click() =~ "edit"
      assert_patch(show_live, ~p"/context/#{context}/edit")

      html =
        show_live
        |> form("#context-form")
        |> render_change(context: @invalid_attrs)

      assert html =~ "can&#39;t be blank"
      assert html =~ "tags must be comma or space delimited"

      {:ok, _live, html} =
        show_live
        |> form("#context-form")
        |> render_submit(context: Map.put(@update_attrs, "slug", context.slug))
        |> follow_redirect(conn, ~p"/context/#{context}")

      assert html =~ "#{context.slug} saved"
      assert html =~ "tag2"
    end

    test "deletes context", %{conn: conn, context: context} do
      {:ok, show_live, _html} = live(conn, ~p"/context/#{context}")

      {:ok, index_live, _html} =
        show_live
        |> element(~s/button[aria-label="delete #{context.slug}"]/)
        |> render_click()
        |> follow_redirect(conn, ~p"/contexts")

      refute has_element?(index_live, "#context-#{context.id}")
    end
  end

  describe "show with note" do
    setup [:register_and_log_in_user]

    setup %{current_user: current_user} do
      %{slug: note_slug} = note = note_fixture(current_user)

      [
        note: note,
        context:
          context_fixture(
            %{content: "example with backlink to [[#{note_slug}]] note"},
            current_user
          )
      ]
    end

    test "searches by tag", %{conn: conn, context: %{tags: [tag]} = context} do
      {:ok, show_live, html} = live(conn, ~p"/context/#{context}")

      assert html =~ tag
      assert show_live |> element("a", tag) |> render_click()
      assert_redirect(show_live, ~p"/contexts/#{tag}")
    end

    test "displays context", %{conn: conn, context: context, note: %{slug: note_slug}} do
      {:ok, show_live, html} = live(conn, ~p"/context/#{context}")

      assert html =~ "context"
      assert html =~ ~p"/note/#{note_slug}"
      assert has_element?(show_live, "a", note_slug)
    end
  end
end
