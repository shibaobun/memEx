defmodule MemexWeb.PipelineLiveTest do
  use MemexWeb.ConnCase

  import Phoenix.LiveViewTest
  import Memex.PipelinesFixtures

  @create_attrs %{description: "some description", title: "some title", visibility: :public}
  @update_attrs %{description: "some updated description", title: "some updated title", visibility: :private}
  @invalid_attrs %{description: nil, title: nil, visibility: nil}

  defp create_pipeline(_) do
    pipeline = pipeline_fixture()
    %{pipeline: pipeline}
  end

  describe "Index" do
    setup [:create_pipeline]

    test "lists all pipelines", %{conn: conn, pipeline: pipeline} do
      {:ok, _index_live, html} = live(conn, Routes.pipeline_index_path(conn, :index))

      assert html =~ "Listing Pipelines"
      assert html =~ pipeline.description
    end

    test "saves new pipeline", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, Routes.pipeline_index_path(conn, :index))

      assert index_live |> element("a", "New Pipeline") |> render_click() =~
               "New Pipeline"

      assert_patch(index_live, Routes.pipeline_index_path(conn, :new))

      assert index_live
             |> form("#pipeline-form", pipeline: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#pipeline-form", pipeline: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.pipeline_index_path(conn, :index))

      assert html =~ "Pipeline created successfully"
      assert html =~ "some description"
    end

    test "updates pipeline in listing", %{conn: conn, pipeline: pipeline} do
      {:ok, index_live, _html} = live(conn, Routes.pipeline_index_path(conn, :index))

      assert index_live |> element("#pipeline-#{pipeline.id} a", "Edit") |> render_click() =~
               "Edit Pipeline"

      assert_patch(index_live, Routes.pipeline_index_path(conn, :edit, pipeline))

      assert index_live
             |> form("#pipeline-form", pipeline: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#pipeline-form", pipeline: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.pipeline_index_path(conn, :index))

      assert html =~ "Pipeline updated successfully"
      assert html =~ "some updated description"
    end

    test "deletes pipeline in listing", %{conn: conn, pipeline: pipeline} do
      {:ok, index_live, _html} = live(conn, Routes.pipeline_index_path(conn, :index))

      assert index_live |> element("#pipeline-#{pipeline.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#pipeline-#{pipeline.id}")
    end
  end

  describe "Show" do
    setup [:create_pipeline]

    test "displays pipeline", %{conn: conn, pipeline: pipeline} do
      {:ok, _show_live, html} = live(conn, Routes.pipeline_show_path(conn, :show, pipeline))

      assert html =~ "Show Pipeline"
      assert html =~ pipeline.description
    end

    test "updates pipeline within modal", %{conn: conn, pipeline: pipeline} do
      {:ok, show_live, _html} = live(conn, Routes.pipeline_show_path(conn, :show, pipeline))

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Pipeline"

      assert_patch(show_live, Routes.pipeline_show_path(conn, :edit, pipeline))

      assert show_live
             |> form("#pipeline-form", pipeline: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        show_live
        |> form("#pipeline-form", pipeline: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.pipeline_show_path(conn, :show, pipeline))

      assert html =~ "Pipeline updated successfully"
      assert html =~ "some updated description"
    end
  end
end
