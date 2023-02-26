defmodule MemexWeb.ErrorView do
  use MemexWeb, :view
  import MemexWeb.Components.Topbar
  alias MemexWeb.{Endpoint, HomeLive}

  def template_not_found(error_path, _assigns) do
    error_string =
      case error_path do
        "404.html" -> dgettext("errors", "Not found")
        "401.html" -> dgettext("errors", "Unauthorized")
        _other_path -> dgettext("errors", "Internal Server Error")
      end

    render("error.html", %{error_string: error_string})
  end
end
