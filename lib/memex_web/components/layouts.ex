defmodule MemexWeb.Layouts do
  @moduledoc """
  The root layouts for the entire application
  """

  use MemexWeb, :html

  embed_templates "layouts/*"

  def get_title(%{assigns: %{title: title}}) when title not in [nil, ""] do
    gettext("memEx | %{title}", title: title)
  end

  def get_title(_conn) do
    gettext("memEx")
  end
end
