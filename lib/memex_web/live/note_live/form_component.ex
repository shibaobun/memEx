defmodule MemexWeb.NoteLive.FormComponent do
  use MemexWeb, :live_component

  alias Memex.Notes

  @impl true
  def update(%{note: note, current_user: current_user} = assigns, socket) do
    changeset = Notes.change_note(note, current_user)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event(
        "validate",
        %{"note" => note_params},
        %{assigns: %{note: note, current_user: current_user}} = socket
      ) do
    changeset =
      note
      |> Notes.change_note(note_params, current_user)
      |> Map.put(:action, :validate)

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
    case Notes.update_note(note, note_params, current_user) do
      {:ok, %{slug: slug}} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("%{slug} saved", slug: slug))
         |> push_navigate(to: return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_note(
         %{assigns: %{return_to: return_to, current_user: current_user}} = socket,
         :new,
         note_params
       ) do
    case Notes.create_note(note_params, current_user) do
      {:ok, %{slug: slug}} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("%{slug} created", slug: slug))
         |> push_navigate(to: return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
