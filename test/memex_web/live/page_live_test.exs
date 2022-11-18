defmodule MemexWeb.HomeLiveTest do
  use MemexWeb.ConnCase

  import Phoenix.LiveViewTest

  test "disconnected and connected render", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/")
    assert disconnected_html =~ "memex"
    assert render(page_live) =~ "memex"
  end
end
