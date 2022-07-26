defmodule MemexWeb.ContextLive.FormComponent do
  use MemexWeb, :live_component

  alias Memex.Contexts

  @impl true
  def update(%{context: context} = assigns, socket) do
    changeset = Contexts.change_context(context)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"context" => context_params}, socket) do
    changeset =
      socket.assigns.context
      |> Contexts.change_context(context_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"context" => context_params}, socket) do
    save_context(socket, socket.assigns.action, context_params)
  end

  defp save_context(socket, :edit, context_params) do
    case Contexts.update_context(socket.assigns.context, context_params) do
      {:ok, _context} ->
        {:noreply,
         socket
         |> put_flash(:info, "Context updated successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_context(socket, :new, context_params) do
    case Contexts.create_context(context_params) do
      {:ok, _context} ->
        {:noreply,
         socket
         |> put_flash(:info, "Context created successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
