defmodule MemexWeb.ContextLive.Index do
  use MemexWeb, :live_view
  alias Memex.{Contexts, Contexts.Context}

  @impl true
  def mount(%{"search" => search}, _session, socket) do
    {:ok, socket |> assign(search: search) |> display_contexts()}
  end

  def mount(_params, _session, socket) do
    {:ok, socket |> assign(search: nil) |> display_contexts()}
  end

  @impl true
  def handle_params(params, _url, %{assigns: %{live_action: live_action}} = socket) do
    {:noreply, apply_action(socket, live_action, params)}
  end

  defp apply_action(%{assigns: %{current_user: current_user}} = socket, :edit, %{"id" => id}) do
    %{title: title} = context = Contexts.get_context!(id, current_user)

    socket
    |> assign(page_title: gettext("edit %{title}", title: title))
    |> assign(context: context)
  end

  defp apply_action(%{assigns: %{current_user: %{id: current_user_id}}} = socket, :new, _params) do
    socket
    |> assign(page_title: gettext("new context"))
    |> assign(context: %Context{user_id: current_user_id})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(page_title: gettext("contexts"))
    |> assign(search: nil)
    |> assign(context: nil)
    |> display_contexts()
  end

  defp apply_action(socket, :search, %{"search" => search}) do
    socket
    |> assign(page_title: gettext("contexts"))
    |> assign(search: search)
    |> assign(context: nil)
    |> display_contexts()
  end

  @impl true
  def handle_event("delete", %{"id" => id}, %{assigns: %{current_user: current_user}} = socket) do
    context = Contexts.get_context!(id, current_user)
    {:ok, %{title: title}} = Contexts.delete_context(context, current_user)

    socket =
      socket
      |> assign(contexts: Contexts.list_contexts(current_user))
      |> put_flash(:info, gettext("%{title} deleted", title: title))

    {:noreply, socket}
  end

  @impl true
  def handle_event("search", %{"search" => %{"search_term" => ""}}, socket) do
    {:noreply, socket |> push_patch(to: Routes.context_index_path(Endpoint, :index))}
  end

  def handle_event("search", %{"search" => %{"search_term" => search_term}}, socket) do
    {:noreply,
     socket |> push_patch(to: Routes.context_index_path(Endpoint, :search, search_term))}
  end

  defp display_contexts(%{assigns: %{current_user: current_user, search: search}} = socket)
       when not (current_user |> is_nil()) do
    socket |> assign(contexts: Contexts.list_contexts(search, current_user))
  end

  defp display_contexts(%{assigns: %{search: search}} = socket) do
    socket |> assign(contexts: Contexts.list_public_contexts(search))
  end
end
