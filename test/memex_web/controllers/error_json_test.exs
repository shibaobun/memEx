defmodule MemexWeb.ErrorJSONTest do
  use MemexWeb.ConnCase, async: true
  alias MemexWeb.ErrorJSON

  test "renders 404" do
    assert ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "not found"}}
  end

  test "renders 500" do
    assert ErrorJSON.render("500.json", %{}) == %{errors: %{detail: "internal server error"}}
  end
end
