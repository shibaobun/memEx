defmodule MemexWeb.LayoutView do
  use MemexWeb, :view
  import MemexWeb.{Components.Topbar, Gettext}
  alias MemexWeb.HomeLive

  # Phoenix LiveDashboard is available only in development by default,
  # so we instruct Elixir to not warn if the dashboard route is missing.
  @compile {:no_warn_undefined, {Routes, :live_dashboard_path, 2}}

  def get_title(%{assigns: %{title: title}}), do: gettext("memEx | %{title}", title: title)
  def get_title(_conn), do: gettext("memEx")
end
