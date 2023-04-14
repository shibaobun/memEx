defmodule MemexWeb.ErrorHTML do
  use MemexWeb, :html

  embed_templates "error_html/*"

  def render(template, _assigns) do
    error_string =
      case template do
        "404.html" -> dgettext("errors", "not found")
        "401.html" -> dgettext("errors", "unauthorized")
        _other_path -> dgettext("errors", "internal server error")
      end

    error(%{error_string: error_string})
  end
end
