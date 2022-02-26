defmodule LokalWeb.ErrorView do
  use LokalWeb, :view
  import LokalWeb.Components.Topbar
  alias LokalWeb.{Endpoint, PageLive}

  def template_not_found(error_path, _assigns) do
    error_string =
      case error_path do
        "404.html" -> dgettext("errors", "Not found")
        "401.html" -> dgettext("errors", "Unauthorized")
        _ -> dgettext("errors", "Internal Server Error")
      end

    render("error.html", %{error_string: error_string})
  end
end
