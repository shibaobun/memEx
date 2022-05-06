defmodule LokalWeb.HomeLiveTest do
  use LokalWeb.ConnCase

  import Phoenix.LiveViewTest

  test "disconnected and connected render", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, "/")
    assert disconnected_html =~ "Welcome to Lokal"
    assert render(page_live) =~ "Welcome to Lokal"
  end
end
