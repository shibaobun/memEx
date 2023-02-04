defmodule LokalWeb.LayoutView do
  use LokalWeb, :view
  import LokalWeb.Components.Topbar
  alias LokalWeb.{Endpoint, HomeLive}

  # Phoenix LiveDashboard is available only in development by default,
  # so we instruct Elixir to not warn if the dashboard route is missing.
  @compile {:no_warn_undefined, {Routes, :live_dashboard_path, 2}}

  def get_title(%{assigns: %{title: title}}) when title not in [nil, ""] do
    gettext("Lokal | %{title}", title: title)
  end

  def get_title(_conn) do
    gettext("Lokal")
  end
end
