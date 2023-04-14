defmodule MemexWeb.HomeLiveTest do
  use MemexWeb.ConnCase

  import Phoenix.LiveViewTest

  test "disconnected and connected render", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, ~p"/")
    assert disconnected_html =~ "memEx"
    assert render(page_live) =~ "memEx"
  end

  test "displays version number", %{conn: conn} do
    {:ok, home_live, disconnected_html} = live(conn, ~p"/")
    assert disconnected_html =~ Mix.Project.config()[:version]
    assert render(home_live) =~ Mix.Project.config()[:version]
  end
end
