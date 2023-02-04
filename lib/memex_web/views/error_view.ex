defmodule MemexWeb.ErrorView do
  use MemexWeb, :view
  import MemexWeb.Components.Topbar
  alias MemexWeb.HomeLive

  def template_not_found(error_path, _assigns) do
    error_string =
      case error_path do
        "404.html" -> dgettext("errors", "not found")
        "401.html" -> dgettext("errors", "unauthorized")
        _other_path -> dgettext("errors", "internal server error")
      end

    render("error.html", %{error_string: error_string})
  end
end
