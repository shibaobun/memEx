defmodule MemexWeb.ErrorHTMLTest do
  use MemexWeb.ConnCase, async: true
  # Bring render_to_string/4 for testing custom views
  import Phoenix.Template
  alias MemexWeb.ErrorHTML

  test "renders 404.html" do
    assert render_to_string(ErrorHTML, "404", "html", []) =~ "not found"
  end

  test "renders 500.html" do
    assert render_to_string(ErrorHTML, "500", "html", []) =~ "internal server error"
  end
end
