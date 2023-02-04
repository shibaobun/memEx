defmodule MemexWeb.PipelineLiveTest do
  use MemexWeb.ConnCase
  import Phoenix.LiveViewTest
  import Memex.{PipelinesFixtures, StepsFixtures}

  @create_attrs %{
    "description" => "some description",
    "tags_string" => "tag1",
    "slug" => "some-slug",
    "visibility" => :public
  }
  @update_attrs %{
    "description" => "some updated description",
    "tags_string" => "tag1,tag2",
    "slug" => "some-updated-slug",
    "visibility" => :private
  }
  @invalid_attrs %{
    "description" => nil,
    "tags_string" => " ",
    "slug" => nil,
    "visibility" => nil
  }
  @step_create_attrs %{
    "content" => "some content",
    "title" => "some title"
  }
  @step_update_attrs %{
    "content" => "some updated content",
    "title" => "some updated title"
  }
  @step_invalid_attrs %{
    "content" => nil,
    "title" => nil
  }

  defp create_pipeline(%{current_user: current_user}) do
    [pipeline: pipeline_fixture(current_user)]
  end

  describe "Index" do
    setup [:register_and_log_in_user, :create_pipeline]

    test "lists all pipelines", %{conn: conn, pipeline: pipeline} do
      {:ok, _index_live, html} = live(conn, Routes.pipeline_index_path(conn, :index))

      assert html =~ "pipelines"
      assert html =~ pipeline.description
    end

    test "searches by tag", %{conn: conn} do
      {:ok, index_live, html} = live(conn, Routes.pipeline_index_path(conn, :index))

      assert html =~ "example-tag"
      assert index_live |> element("a", "example-tag") |> render_click()
      assert_patch(index_live, Routes.pipeline_index_path(conn, :search, "example-tag"))
    end

    test "saves new pipeline", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, Routes.pipeline_index_path(conn, :index))

      assert index_live |> element("a", "new pipeline") |> render_click() =~
               "new pipeline"

      assert_patch(index_live, Routes.pipeline_index_path(conn, :new))

      assert index_live
             |> form("#pipeline-form", pipeline: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#pipeline-form", pipeline: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.pipeline_index_path(conn, :index))

      assert html =~ "#{@create_attrs |> Map.get("slug")} created"
      assert html =~ "some description"
    end

    test "updates pipeline in listing", %{conn: conn, pipeline: pipeline} do
      {:ok, index_live, _html} = live(conn, Routes.pipeline_index_path(conn, :index))

      assert index_live |> element("[data-qa=\"pipeline-edit-#{pipeline.id}\"]") |> render_click() =~
               "edit"

      assert_patch(index_live, Routes.pipeline_index_path(conn, :edit, pipeline.slug))

      assert index_live
             |> form("#pipeline-form", pipeline: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#pipeline-form", pipeline: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.pipeline_index_path(conn, :index))

      assert html =~ "#{@update_attrs |> Map.get("slug")} saved"
      assert html =~ "some updated description"
    end

    test "deletes pipeline in listing", %{conn: conn, pipeline: pipeline} do
      {:ok, index_live, _html} = live(conn, Routes.pipeline_index_path(conn, :index))

      assert index_live
             |> element("[data-qa=\"delete-pipeline-#{pipeline.id}\"]")
             |> render_click()

      refute has_element?(index_live, "#pipeline-#{pipeline.id}")
    end
  end

  describe "show" do
    setup [:register_and_log_in_user, :create_pipeline]

    test "displays pipeline", %{conn: conn, pipeline: pipeline} do
      {:ok, _show_live, html} = live(conn, Routes.pipeline_show_path(conn, :show, pipeline.slug))

      assert html =~ "pipeline"
      assert html =~ pipeline.description
    end

    test "updates pipeline within modal", %{conn: conn, pipeline: pipeline} do
      {:ok, show_live, _html} = live(conn, Routes.pipeline_show_path(conn, :show, pipeline.slug))

      assert show_live |> element("a", "edit") |> render_click() =~ "edit"

      assert_patch(show_live, Routes.pipeline_show_path(conn, :edit, pipeline.slug))

      html =
        show_live
        |> form("#pipeline-form", pipeline: @invalid_attrs)
        |> render_change()

      assert html =~ "can&#39;t be blank"
      assert html =~ "tags must be comma-delimited"

      {:ok, _, html} =
        show_live
        |> form("#pipeline-form", pipeline: Map.put(@update_attrs, "slug", pipeline.slug))
        |> render_submit()
        |> follow_redirect(conn, Routes.pipeline_show_path(conn, :show, pipeline.slug))

      assert html =~ "#{pipeline.slug} saved"
      assert html =~ "some updated description"
    end

    test "deletes pipeline", %{conn: conn, pipeline: pipeline} do
      {:ok, show_live, _html} = live(conn, Routes.pipeline_show_path(conn, :show, pipeline.slug))

      {:ok, index_live, _html} =
        show_live
        |> element("[data-qa=\"delete-pipeline-#{pipeline.id}\"]")
        |> render_click()
        |> follow_redirect(conn, Routes.pipeline_index_path(conn, :index))

      refute has_element?(index_live, "#pipeline-#{pipeline.id}")
    end

    test "creates a step", %{conn: conn, pipeline: pipeline} do
      {:ok, show_live, _html} = live(conn, Routes.pipeline_show_path(conn, :show, pipeline.slug))

      show_live
      |> element("[data-qa=\"add-step-#{pipeline.id}\"]")
      |> render_click()

      assert_patch(show_live, Routes.pipeline_show_path(conn, :add_step, pipeline.slug))

      {:ok, _show_live, html} =
        show_live
        |> form("#step-form", step: @step_create_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.pipeline_show_path(conn, :show, pipeline.slug))

      assert html =~ "some title created"
      assert html =~ "some description"
    end
  end

  describe "show with a step" do
    setup [:register_and_log_in_user, :create_pipeline]

    setup %{pipeline: pipeline, current_user: current_user} do
      [
        step: step_fixture(0, pipeline, current_user)
      ]
    end

    test "searches by tag", %{conn: conn, pipeline: pipeline} do
      {:ok, show_live, html} = live(conn, Routes.pipeline_show_path(conn, :show, pipeline.slug))

      assert html =~ "example-tag"
      assert show_live |> element("a", "example-tag") |> render_click()
      assert_redirect(show_live, Routes.pipeline_index_path(conn, :search, "example-tag"))
    end

    test "updates a step", %{conn: conn, pipeline: pipeline, step: step} do
      {:ok, show_live, _html} = live(conn, Routes.pipeline_show_path(conn, :show, pipeline.slug))

      show_live
      |> element("[data-qa=\"edit-step-#{step.id}\"]")
      |> render_click()

      assert_patch(show_live, Routes.pipeline_show_path(conn, :edit_step, pipeline.slug, step.id))

      assert show_live
             |> form("#step-form", step: @step_invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _show_live, html} =
        show_live
        |> form("#step-form", step: @step_update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.pipeline_show_path(conn, :show, pipeline.slug))

      assert html =~ "some updated title saved"
      assert html =~ "some updated content"
    end

    test "deletes a step", %{conn: conn, pipeline: pipeline, step: step} do
      {:ok, show_live, _html} = live(conn, Routes.pipeline_show_path(conn, :show, pipeline.slug))

      html =
        show_live
        |> element("[data-qa=\"delete-step-#{step.id}\"]")
        |> render_click()

      assert_patch(show_live, Routes.pipeline_show_path(conn, :show, pipeline.slug))

      assert html =~ "some title deleted"
      refute html =~ "some updated content"
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
      {:ok, show_live, _html} = live(conn, Routes.pipeline_show_path(conn, :show, pipeline.slug))

      html =
        show_live
        |> element("[data-qa=\"move-step-up-#{second_step.id}\"]")
        |> render_click()

      assert html =~ "1. second step"
      assert html =~ "2. first step"
      assert html =~ "3. third step"

      refute has_element?(show_live, "[data-qa=\"move-step-up-#{second_step.id}\"]")

      html =
        show_live
        |> element("[data-qa=\"move-step-down-#{first_step.id}\"]")
        |> render_click()

      assert html =~ "1. second step"
      assert html =~ "2. third step"
      assert html =~ "3. first step"

      refute has_element?(show_live, "[data-qa=\"move-step-down-#{first_step.id}\"]")
    end
  end
end
