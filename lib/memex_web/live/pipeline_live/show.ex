defmodule MemexWeb.PipelineLive.Show do
  use MemexWeb, :live_view

  alias Memex.Pipelines

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:pipeline, Pipelines.get_pipeline!(id))}
  end

  defp page_title(:show), do: "show pipeline"
  defp page_title(:edit), do: "edit pipeline"
end
