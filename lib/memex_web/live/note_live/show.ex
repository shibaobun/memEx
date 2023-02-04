defmodule MemexWeb.NoteLive.Show do
  use MemexWeb, :live_view
  import MemexWeb.Components.NoteContent
  alias Memex.{Accounts.User, Notes, Notes.Note}

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
      |> push_navigate(to: Routes.note_index_path(Endpoint, :index))

    {:noreply, socket}
  end

  defp page_title(:show, %{slug: slug}), do: slug
  defp page_title(:edit, %{slug: slug}), do: gettext("edit %{slug}", slug: slug)

  @spec is_owner_or_admin?(Note.t(), User.t()) :: boolean()
  defp is_owner_or_admin?(%{user_id: user_id}, %{id: user_id}), do: true
  defp is_owner_or_admin?(_context, %{role: :admin}), do: true
  defp is_owner_or_admin?(_context, _other_user), do: false

  @spec is_owner?(Note.t(), User.t()) :: boolean()
  defp is_owner?(%{user_id: user_id}, %{id: user_id}), do: true
  defp is_owner?(_context, _other_user), do: false
end
