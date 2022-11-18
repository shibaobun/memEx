defmodule MemexWeb.ContextLive.Index do
  use MemexWeb, :live_view

  alias Memex.Contexts
  alias Memex.Contexts.Context

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :contexts, list_contexts())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "edit context")
    |> assign(:context, Contexts.get_context!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "new context")
    |> assign(:context, %Context{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "listing contexts")
    |> assign(:context, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    context = Contexts.get_context!(id)
    {:ok, _} = Contexts.delete_context(context)

    {:noreply, assign(socket, :contexts, list_contexts())}
  end

  defp list_contexts do
    Contexts.list_contexts()
  end
end
