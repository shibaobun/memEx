defmodule MemexWeb.ErrorViewTest do
  @moduledoc """
  Tests the error view
  """

  use MemexWeb.ConnCase, async: true
  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View

  @moduletag :error_view_test

  test "renders 404.html" do
    assert render_to_string(MemexWeb.ErrorView, "404.html", []) =~ "not found"
  end

  test "renders 500.html" do
    assert render_to_string(MemexWeb.ErrorView, "500.html", []) =~ "internal server error"
  end
end
