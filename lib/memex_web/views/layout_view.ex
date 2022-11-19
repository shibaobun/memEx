defmodule MemexWeb.LayoutView do
  use MemexWeb, :view
  import MemexWeb.Components.Topbar
  alias MemexWeb.HomeLive

  # Phoenix LiveDashboard is available only in development by default,
  # so we instruct Elixir to not warn if the dashboard route is missing.
  @compile {:no_warn_undefined, {Routes, :live_dashboard_path, 2}}

  def get_title(conn) do
    if conn.assigns |> Map.has_key?(:title) do
      "Memex | #{conn.assigns.title}"
    else
      "Memex"
    end
  end
end
