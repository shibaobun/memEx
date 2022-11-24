defmodule MemexWeb.ContextLive.FormComponent do
  use MemexWeb, :live_component

  alias Memex.Contexts

  @impl true
  def update(%{context: context, current_user: current_user} = assigns, socket) do
    changeset = Contexts.change_context(context, current_user)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event(
        "validate",
        %{"context" => context_params},
        %{assigns: %{context: context, current_user: current_user}} = socket
      ) do
    changeset =
      context
      |> Contexts.change_context(context_params, current_user)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"context" => context_params}, %{assigns: %{action: action}} = socket) do
    save_context(socket, action, context_params)
  end

  defp save_context(
         %{assigns: %{context: context, return_to: return_to, current_user: current_user}} =
           socket,
         :edit,
         context_params
       ) do
    case Contexts.update_context(context, context_params, current_user) do
      {:ok, %{title: title}} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("%{title} saved", title: title))
         |> push_navigate(to: return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_context(
         %{assigns: %{return_to: return_to, current_user: current_user}} = socket,
         :new,
         context_params
       ) do
    case Contexts.create_context(context_params, current_user) do
      {:ok, %{title: title}} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("%{title} created", title: title))
         |> push_navigate(to: return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
