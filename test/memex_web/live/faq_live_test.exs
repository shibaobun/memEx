defmodule MemexWeb.FaqLiveTest do
  use MemexWeb.ConnCase

  import Phoenix.LiveViewTest

  test "disconnected and connected render", %{conn: conn} do
    {:ok, page_live, disconnected_html} = live(conn, ~p"/faq")
    assert disconnected_html =~ "faq"
    assert render(page_live) =~ "faq"
  end
end
