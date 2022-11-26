defmodule MemexWeb.ErrorViewTest do
  @moduledoc """
  Tests the error view
  """

  use MemexWeb.ConnCase, async: true
  import MemexWeb.Gettext

  @moduletag :error_view_test

  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View

  test "renders 404.html" do
    assert render_to_string(MemexWeb.ErrorView, "404.html", []) =~
             dgettext("errors", "not found")
  end

  test "renders 500.html" do
    assert render_to_string(MemexWeb.ErrorView, "500.html", []) =~
             dgettext("errors", "internal server error")
  end
end
