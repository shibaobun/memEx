defmodule MemexWeb.ErrorJSON do
  import MemexWeb.Gettext

  def render(template, _assigns) do
    error_string =
      case template do
        "404.json" -> dgettext("errors", "not found")
        "401.json" -> dgettext("errors", "unauthorized")
        _other_path -> dgettext("errors", "internal server error")
      end

    %{errors: %{detail: error_string}}
  end
end
