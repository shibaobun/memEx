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

  defp apply_action(%{assigns: %{current_user: current_user}} = socket, :edit, %{"slug" => slug}) do
    %{slug: slug} = context = Contexts.get_context_by_slug(slug, current_user)

    socket
    |> assign(page_title: gettext("edit %{slug}", slug: slug))
    |> assign(context: context)
  end

  defp apply_action(%{assigns: %{current_user: %{id: current_user_id}}} = socket, :new, _params) do
    socket
    |> assign(page_title: gettext("new context"))
    |> assign(context: %Context{visibility: :private, user_id: current_user_id})
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
    {:ok, %{slug: slug}} = Contexts.delete_context(context, current_user)

    socket =
      socket
      |> assign(contexts: Contexts.list_contexts(current_user))
      |> put_flash(:info, gettext("%{slug} deleted", slug: slug))

    {:noreply, socket}
  end

  def handle_event("search", %{"search" => %{"search_term" => ""}}, socket) do
    {:noreply, socket |> push_patch(to: ~p"/contexts")}
  end

  def handle_event("search", %{"search" => %{"search_term" => search_term}}, socket) do
    redirect_to = ~p"/contexts/#{search_term}"
    {:noreply, socket |> push_patch(to: redirect_to)}
  end

  defp display_contexts(%{assigns: %{current_user: current_user, search: search}} = socket)
       when not (current_user |> is_nil()) do
    socket |> assign(contexts: Contexts.list_contexts(search, current_user))
  end

  defp display_contexts(%{assigns: %{search: search}} = socket) do
    socket |> assign(contexts: Contexts.list_public_contexts(search))
  end
end
