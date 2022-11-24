defmodule MemexWeb.PipelineLiveTest do
  use MemexWeb.ConnCase

  import Phoenix.LiveViewTest
  import Memex.PipelinesFixtures

  @create_attrs %{
    "description" => "some description",
    "tags_string" => "tag1",
    "title" => "some title",
    "visibility" => :public
  }
  @update_attrs %{
    "description" => "some updated description",
    "tags_string" => "tag1,tag2",
    "title" => "some updated title",
    "visibility" => :private
  }
  @invalid_attrs %{
    "description" => nil,
    "tags_string" => "",
    "title" => nil,
    "visibility" => nil
  }

  defp create_pipeline(%{user: user}) do
    [pipeline: pipeline_fixture(user)]
  end

  describe "Index" do
    setup [:register_and_log_in_user, :create_pipeline]

    test "lists all pipelines", %{conn: conn, pipeline: pipeline} do
      {:ok, _index_live, html} = live(conn, Routes.pipeline_index_path(conn, :index))

      assert html =~ "pipelines"
      assert html =~ pipeline.description
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

      assert html =~ "#{@create_attrs |> Map.get("title")} created"
      assert html =~ "some description"
    end

    test "updates pipeline in listing", %{conn: conn, pipeline: pipeline} do
      {:ok, index_live, _html} = live(conn, Routes.pipeline_index_path(conn, :index))

      assert index_live |> element("[data-qa=\"pipeline-edit-#{pipeline.id}\"]") |> render_click() =~
               "edit"

      assert_patch(index_live, Routes.pipeline_index_path(conn, :edit, pipeline))

      assert index_live
             |> form("#pipeline-form", pipeline: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#pipeline-form", pipeline: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.pipeline_index_path(conn, :index))

      assert html =~ "#{@update_attrs |> Map.get("title")} saved"
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
      {:ok, _show_live, html} = live(conn, Routes.pipeline_show_path(conn, :show, pipeline))

      assert html =~ "show pipeline"
      assert html =~ pipeline.description
    end

    test "updates pipeline within modal", %{conn: conn, pipeline: pipeline} do
      {:ok, show_live, _html} = live(conn, Routes.pipeline_show_path(conn, :show, pipeline))

      assert show_live |> element("a", "edit") |> render_click() =~ "edit"

      assert_patch(show_live, Routes.pipeline_show_path(conn, :edit, pipeline))

      assert show_live
             |> form("#pipeline-form", pipeline: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        show_live
        |> form("#pipeline-form", pipeline: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.pipeline_show_path(conn, :show, pipeline))

      assert html =~ "#{@update_attrs |> Map.get("title")} saved"
      assert html =~ "some updated description"
    end

    test "deletes pipeline", %{conn: conn, pipeline: pipeline} do
      {:ok, show_live, _html} = live(conn, Routes.pipeline_show_path(conn, :show, pipeline))

      {:ok, index_live, _html} =
        show_live
        |> element("[data-qa=\"delete-pipeline-#{pipeline.id}\"]")
        |> render_click()
        |> follow_redirect(conn, Routes.pipeline_index_path(conn, :index))

      refute has_element?(index_live, "#pipeline-#{pipeline.id}")
    end
  end
end
