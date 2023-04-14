defmodule MemexWeb.NoteLive.Show do
  use MemexWeb, :live_view
  alias Memex.Notes

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(
        %{"slug" => slug},
        _params,
        %{assigns: %{live_action: live_action, current_user: current_user}} = socket
      ) do
    note =
      case Notes.get_note_by_slug(slug, current_user) do
        nil -> raise MemexWeb.NotFoundError, gettext("%{slug} could not be found", slug: slug)
        note -> note
      end

    socket =
      socket
      |> assign(:page_title, page_title(live_action, note))
      |> assign(:note, note)

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "delete",
        _params,
        %{assigns: %{note: note, current_user: current_user}} = socket
      ) do
    {:ok, %{slug: slug}} = Notes.delete_note(note, current_user)

    socket =
      socket
      |> put_flash(:info, gettext("%{slug} deleted", slug: slug))
      |> push_navigate(to: ~p"/notes")

    {:noreply, socket}
  end

  defp page_title(:show, %{slug: slug}), do: slug
  defp page_title(:edit, %{slug: slug}), do: gettext("edit %{slug}", slug: slug)
end
