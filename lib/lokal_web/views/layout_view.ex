defmodule LokalWeb.LayoutView do
  use LokalWeb, :view
  
  def get_title(conn) do
    if conn.assigns |> Map.has_key?(:title) do
      "Lokal | #{conn.assigns.title}"
    else
      "Lokal"
    end
  end
end
