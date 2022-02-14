defmodule LokalWeb.LayoutView do
  use LokalWeb, :view
  import LokalWeb.Components.Topbar

  # Phoenix LiveDashboard is available only in development by default,
  # so we instruct Elixir to not warn if the dashboard route is missing.
  @compile {:no_warn_undefined, {Routes, :live_dashboard_path, 2}}

  def get_title(conn) do
    if conn.assigns |> Map.has_key?(:title) do
      "Lokal | #{conn.assigns.title}"
    else
      "Lokal"
    end
  end
end
