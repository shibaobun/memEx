defmodule MemexWeb.PipelineLive.Index do
  use MemexWeb, :live_view

  alias Memex.Pipelines
  alias Memex.Pipelines.Pipeline

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :pipelines, list_pipelines())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Pipeline")
    |> assign(:pipeline, Pipelines.get_pipeline!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Pipeline")
    |> assign(:pipeline, %Pipeline{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Pipelines")
    |> assign(:pipeline, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    pipeline = Pipelines.get_pipeline!(id)
    {:ok, _} = Pipelines.delete_pipeline(pipeline)

    {:noreply, assign(socket, :pipelines, list_pipelines())}
  end

  defp list_pipelines do
    Pipelines.list_pipelines()
  end
end
