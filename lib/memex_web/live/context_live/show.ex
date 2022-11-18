defmodule MemexWeb.ContextLive.Show do
  use MemexWeb, :live_view

  alias Memex.Contexts

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:context, Contexts.get_context!(id))}
  end

  defp page_title(:show), do: "show context"
  defp page_title(:edit), do: "edit context"
end
