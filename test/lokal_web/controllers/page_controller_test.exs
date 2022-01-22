defmodule LokalWeb.PageControllerTest do
  use LokalWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Welcome to Lokal"
  end
end
