defmodule MemexWeb.NoteLive.Index do
  use MemexWeb, :live_view
  alias Memex.{Notes, Notes.Note}

  @impl true
  def mount(_params, _session, %{assigns: %{current_user: current_user}} = socket)
      when not (current_user |> is_nil()) do
    {:ok, socket |> assign(notes: Notes.list_notes(current_user))}
  end

  def mount(_params, _session, socket) do
    {:ok, socket |> assign(notes: Notes.list_public_notes())}
  end

  @impl true
  def handle_params(params, _url, %{assigns: %{live_action: live_action}} = socket) do
    {:noreply, apply_action(socket, live_action, params)}
  end

  defp apply_action(%{assigns: %{current_user: current_user}} = socket, :edit, %{"id" => id}) do
    %{title: title} = note = Notes.get_note!(id, current_user)

    socket
    |> assign(page_title: gettext("edit %{title}", title: title))
    |> assign(note: note)
  end

  defp apply_action(%{assigns: %{current_user: %{id: current_user_id}}} = socket, :new, _params) do
    socket
    |> assign(page_title: "new note")
    |> assign(note: %Note{user_id: current_user_id})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(page_title: "notes")
    |> assign(note: nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, %{assigns: %{current_user: current_user}} = socket) do
    %{title: title} = note = Notes.get_note!(id, current_user)
    {:ok, _} = Notes.delete_note(note, current_user)

    socket =
      socket
      |> assign(notes: Notes.list_notes(current_user))
      |> put_flash(:info, gettext("%{title} deleted", title: title))

    {:noreply, socket}
  end
end
