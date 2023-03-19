defmodule MemexWeb.NoteLive.Index do
  use MemexWeb, :live_view
  alias Memex.{Notes, Notes.Note}

  @impl true
  def mount(%{"search" => search}, _session, socket) do
    {:ok, socket |> assign(search: search) |> display_notes()}
  end

  def mount(_params, _session, socket) do
    {:ok, socket |> assign(search: nil) |> display_notes()}
  end

  @impl true
  def handle_params(params, _url, %{assigns: %{live_action: live_action}} = socket) do
    {:noreply, apply_action(socket, live_action, params)}
  end

  defp apply_action(%{assigns: %{current_user: current_user}} = socket, :edit, %{"slug" => slug}) do
    %{slug: slug} = note = Notes.get_note_by_slug(slug, current_user)

    socket
    |> assign(page_title: gettext("edit %{slug}", slug: slug))
    |> assign(note: note)
  end

  defp apply_action(%{assigns: %{current_user: %{id: current_user_id}}} = socket, :new, _params) do
    socket
    |> assign(page_title: gettext("new note"))
    |> assign(note: %Note{visibility: :private, user_id: current_user_id})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(page_title: gettext("notes"))
    |> assign(search: nil)
    |> assign(note: nil)
    |> display_notes()
  end

  defp apply_action(socket, :search, %{"search" => search}) do
    socket
    |> assign(page_title: gettext("notes"))
    |> assign(search: search)
    |> assign(note: nil)
    |> display_notes()
  end

  @impl true
  def handle_event("delete", %{"id" => id}, %{assigns: %{current_user: current_user}} = socket) do
    note = Notes.get_note!(id, current_user)
    {:ok, %{slug: slug}} = Notes.delete_note(note, current_user)

    socket =
      socket
      |> assign(notes: Notes.list_notes(current_user))
      |> put_flash(:info, gettext("%{slug} deleted", slug: slug))

    {:noreply, socket}
  end

  def handle_event("search", %{"search" => %{"search_term" => ""}}, socket) do
    {:noreply, socket |> push_patch(to: Routes.note_index_path(Endpoint, :index))}
  end

  def handle_event("search", %{"search" => %{"search_term" => search_term}}, socket) do
    {:noreply, socket |> push_patch(to: Routes.note_index_path(Endpoint, :search, search_term))}
  end

  defp display_notes(%{assigns: %{current_user: current_user, search: search}} = socket)
       when not (current_user |> is_nil()) do
    socket |> assign(notes: Notes.list_notes(search, current_user))
  end

  defp display_notes(%{assigns: %{search: search}} = socket) do
    socket |> assign(notes: Notes.list_public_notes(search))
  end
end
