defmodule MemexWeb.HomeControllerTest do
  @moduledoc """
  Tests the home page
  """

  use MemexWeb.ConnCase

  @moduletag :home_controller_test

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Welcome to Memex"
  end
end
