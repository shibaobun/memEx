defmodule MemexWeb.NoteLive.Index do
  use MemexWeb, :live_view

  alias Memex.Notes
  alias Memex.Notes.Note

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :notes, list_notes())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(page_title: gettext("edit %{title}", title: title))
    |> assign(:note, Notes.get_note!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(page_title: "new note")
    |> assign(:note, %Note{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(page_title: "notes")
    |> assign(:note, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    note = Notes.get_note!(id)
    {:ok, _} = Notes.delete_note(note)

      |> put_flash(:info, gettext("%{title} deleted", title: title))

  defp list_notes do
    Notes.list_notes()
  end
end
