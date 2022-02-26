defmodule LokalWeb.HomeControllerTest do
  @moduledoc """
  Tests the home page
  """

  use LokalWeb.ConnCase

  @moduletag :home_controller_test

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Welcome to Lokal"
  end
end
