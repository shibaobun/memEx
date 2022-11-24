defmodule MemexWeb.NoteLive.Show do
  use MemexWeb, :live_view

  alias Memex.Notes

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(
        %{"id" => id},
        _,
        %{assigns: %{live_action: live_action, current_user: current_user}} = socket
      ) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(live_action))
     |> assign(:note, Notes.get_note!(id, current_user))}
  end

  @impl true
  def handle_event(
        "delete",
        _params,
        %{assigns: %{note: note, current_user: current_user}} = socket
      ) do
    {:ok, %{title: title}} = Notes.delete_note(note, current_user)

    socket =
      socket
      |> put_flash(:info, gettext("%{title} deleted", title: title))
      |> push_navigate(to: Routes.note_index_path(Endpoint, :index))

    {:noreply, socket}
  end

  defp page_title(:show), do: gettext("show note")
  defp page_title(:edit), do: gettext("edit note")
end
