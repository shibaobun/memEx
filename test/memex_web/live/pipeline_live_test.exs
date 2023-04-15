defmodule MemexWeb.PipelineLiveTest do
  use MemexWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  import Memex.Fixtures

  @create_attrs %{
    description: "some description",
    tags_string: "tag1",
    slug: "some-slug",
    visibility: :public
  }
  @update_attrs %{
    description: "some updated description",
    tags_string: "tag1,tag2",
    slug: "some-updated-slug",
    visibility: :private
  }
  @invalid_attrs %{
    description: nil,
    tags_string: "invalid tags",
    slug: nil,
    visibility: nil
  }
  @step_create_attrs %{
    content: "some content",
    title: "some title"
  }
  @step_update_attrs %{
    content: "some updated content",
    title: "some updated title"
  }
  @step_invalid_attrs %{
    content: nil,
    title: nil
  }

  defp create_pipeline(%{current_user: current_user}) do
    [pipeline: pipeline_fixture(current_user)]
  end

  describe "Index" do
    setup [:register_and_log_in_user, :create_pipeline]

    test "lists all pipelines", %{conn: conn, pipeline: pipeline} do
      {:ok, _index_live, html} = live(conn, ~p"/pipelines")

      assert html =~ "pipelines"
      assert html =~ pipeline.description
    end

    test "searches by tag", %{conn: conn, pipeline: %{tags: [tag]}} do
      {:ok, index_live, html} = live(conn, ~p"/pipelines")

      assert html =~ tag
      assert index_live |> element("a", tag) |> render_click()
      assert_patch(index_live, ~p"/pipelines/#{tag}")
    end

    test "saves new pipeline", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/pipelines")

      assert index_live |> element("a", "new pipeline") |> render_click() =~ "new pipeline"
      assert_patch(index_live, ~p"/pipelines/new")

      assert index_live
             |> form("#pipeline-form")
             |> render_change(pipeline: @invalid_attrs) =~ "can&#39;t be blank"

      {:ok, _live, html} =
        index_live
        |> form("#pipeline-form")
        |> render_submit(pipeline: @create_attrs)
        |> follow_redirect(conn, ~p"/pipelines")

      assert html =~ "#{@create_attrs.slug} created"
      assert html =~ @create_attrs.description
    end

    test "updates pipeline in listing", %{conn: conn, pipeline: pipeline} do
      {:ok, index_live, _html} = live(conn, ~p"/pipelines")

      assert index_live |> element(~s/a[aria-label="edit #{pipeline.slug}"]/) |> render_click() =~
               "edit"

      assert_patch(index_live, ~p"/pipelines/#{pipeline}/edit")

      assert index_live
             |> form("#pipeline-form")
             |> render_change(pipeline: @invalid_attrs) =~ "can&#39;t be blank"

      {:ok, _live, html} =
        index_live
        |> form("#pipeline-form")
        |> render_submit(pipeline: @update_attrs)
        |> follow_redirect(conn, ~p"/pipelines")

      assert html =~ "#{@update_attrs.slug} saved"
      assert html =~ @update_attrs.description
    end

    test "deletes pipeline in listing", %{conn: conn, pipeline: pipeline} do
      {:ok, index_live, _html} = live(conn, ~p"/pipelines")

      assert index_live
             |> element(~s/a[aria-label="delete #{pipeline.slug}"]/)
             |> render_click()

      refute has_element?(index_live, "#pipeline-#{pipeline.id}")
    end
  end

  describe "show" do
    setup [:register_and_log_in_user, :create_pipeline]

    test "displays pipeline", %{conn: conn, pipeline: pipeline} do
      {:ok, _show_live, html} = live(conn, ~p"/pipeline/#{pipeline}")

      assert html =~ "pipeline"
      assert html =~ pipeline.description
    end

    test "updates pipeline within modal", %{conn: conn, pipeline: pipeline} do
      {:ok, show_live, _html} = live(conn, ~p"/pipeline/#{pipeline}")
      assert show_live |> element("a", "edit") |> render_click() =~ "edit"
      assert_patch(show_live, ~p"/pipeline/#{pipeline}/edit")

      html =
        show_live
        |> form("#pipeline-form")
        |> render_change(pipeline: @invalid_attrs)

      assert html =~ "can&#39;t be blank"
      assert html =~ "tags must be comma-delimited"

      {:ok, _live, html} =
        show_live
        |> form("#pipeline-form")
        |> render_submit(pipeline: @update_attrs |> Map.put(:slug, pipeline.slug))
        |> follow_redirect(conn, ~p"/pipeline/#{pipeline}")

      assert html =~ "#{pipeline.slug} saved"
      assert html =~ @update_attrs.description
    end

    test "deletes pipeline", %{conn: conn, pipeline: pipeline} do
      {:ok, show_live, _html} = live(conn, ~p"/pipeline/#{pipeline}")

      {:ok, index_live, _html} =
        show_live
        |> element(~s/button[aria-label="delete #{pipeline.slug}"]/)
        |> render_click()
        |> follow_redirect(conn, ~p"/pipelines")

      refute has_element?(index_live, "#pipeline-#{pipeline.id}")
    end

    test "creates a step", %{conn: conn, pipeline: pipeline} do
      {:ok, show_live, _html} = live(conn, ~p"/pipeline/#{pipeline}")
      show_live |> element("a", "add step") |> render_click()
      assert_patch(show_live, ~p"/pipeline/#{pipeline}/add_step")

      {:ok, _show_live, html} =
        show_live
        |> form("#step-form")
        |> render_submit(step: @step_create_attrs)
        |> follow_redirect(conn, ~p"/pipeline/#{pipeline}")

      assert html =~ @step_create_attrs.title
      assert html =~ @step_create_attrs.content
    end
  end

  describe "show with a step" do
    setup [:register_and_log_in_user, :create_pipeline]

    setup %{pipeline: pipeline, current_user: current_user} do
      [
        step: step_fixture(0, pipeline, current_user)
      ]
    end

    test "searches by tag", %{conn: conn, pipeline: %{tags: [tag]} = pipeline} do
      {:ok, show_live, html} = live(conn, ~p"/pipeline/#{pipeline}")

      assert html =~ tag
      assert show_live |> element("a", tag) |> render_click()
      assert_redirect(show_live, ~p"/pipelines/#{tag}")
    end

    test "updates a step", %{conn: conn, pipeline: pipeline, step: step} do
      {:ok, show_live, _html} = live(conn, ~p"/pipeline/#{pipeline}")

      show_live
      |> element(~s/a[aria-label="edit #{step.title}"]/)
      |> render_click()

      assert_patch(show_live, ~p"/pipeline/#{pipeline}/#{step.id}")

      assert show_live
             |> form("#step-form")
             |> render_change(step: @step_invalid_attrs) =~ "can&#39;t be blank"

      {:ok, _show_live, html} =
        show_live
        |> form("#step-form")
        |> render_submit(step: @step_update_attrs)
        |> follow_redirect(conn, ~p"/pipeline/#{pipeline}")

      assert html =~ @step_update_attrs.title
      assert html =~ @step_update_attrs.content
    end

    test "deletes a step", %{conn: conn, pipeline: pipeline, step: step} do
      {:ok, show_live, _html} = live(conn, ~p"/pipeline/#{pipeline}")

      html =
        show_live
        |> element(~s/button[aria-label="delete #{step.title}"]/)
        |> render_click()

      assert_patch(show_live, ~p"/pipeline/#{pipeline}")

      assert html =~ "#{step.title} deleted"
      refute html =~ step.content
    end
  end

  describe "show with multiple steps" do
    setup [:register_and_log_in_user, :create_pipeline]

    setup %{pipeline: pipeline, current_user: current_user} do
      [
        first_step: step_fixture(%{title: "first step"}, 0, pipeline, current_user),
        second_step: step_fixture(%{title: "second step"}, 1, pipeline, current_user),
        third_step: step_fixture(%{title: "third step"}, 2, pipeline, current_user)
      ]
    end

    test "reorders a step",
         %{conn: conn, pipeline: pipeline, first_step: first_step, second_step: second_step} do
      {:ok, show_live, _html} = live(conn, ~p"/pipeline/#{pipeline}")

      html =
        show_live
        |> element(~s/button[aria-label="move #{second_step.title} up"]/)
        |> render_click()

      assert html =~ "1. second step"
      assert html =~ "2. first step"
      assert html =~ "3. third step"

      refute has_element?(show_live, ~s/button[aria-label="move #{second_step.title} up"]/)

      html =
        show_live
        |> element(~s/button[aria-label="move #{first_step.title} down"]/)
        |> render_click()

      assert html =~ "1. second step"
      assert html =~ "2. third step"
      assert html =~ "3. first step"

      refute has_element?(show_live, ~s/button[aria-label="move #{first_step.title} down"]/)
    end
  end
end
