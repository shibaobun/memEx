defmodule MemexWeb.NoteLive.FormComponent do
  use MemexWeb, :live_component
  alias Ecto.Changeset
  alias Memex.Notes

  @impl true
  def update(%{note: note, current_user: current_user} = assigns, socket) do
    changeset = Notes.change_note(note, current_user)

    socket =
      socket
      |> assign(assigns)
      |> assign(:changeset, changeset)

    {:ok, socket}
  end

  @impl true
  def handle_event(
        "validate",
        %{"note" => note_params},
        %{assigns: %{note: note, current_user: current_user}} = socket
      ) do
    changeset = note |> Notes.change_note(note_params, current_user)

    changeset =
      case changeset |> Changeset.apply_action(:validate) do
        {:ok, _data} -> changeset
        {:error, changeset} -> changeset
      end

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"note" => note_params}, %{assigns: %{action: action}} = socket) do
    save_note(socket, action, note_params)
  end

  defp save_note(
         %{assigns: %{note: note, return_to: return_to, current_user: current_user}} = socket,
         :edit,
         note_params
       ) do
    socket =
      case Notes.update_note(note, note_params, current_user) do
        {:ok, %{slug: slug}} ->
          socket
          |> put_flash(:info, gettext("%{slug} saved", slug: slug))
          |> push_navigate(to: return_to)

        {:error, %Changeset{} = changeset} ->
          assign(socket, :changeset, changeset)
      end

    {:noreply, socket}
  end

  defp save_note(
         %{assigns: %{return_to: return_to, current_user: current_user}} = socket,
         :new,
         note_params
       ) do
    socket =
      case Notes.create_note(note_params, current_user) do
        {:ok, %{slug: slug}} ->
          socket
          |> put_flash(:info, gettext("%{slug} created", slug: slug))
          |> push_navigate(to: return_to)

        {:error, %Changeset{} = changeset} ->
          assign(socket, changeset: changeset)
      end

    {:noreply, socket}
  end
end
