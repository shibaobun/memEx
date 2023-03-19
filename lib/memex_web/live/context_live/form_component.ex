defmodule MemexWeb.ContextLive.FormComponent do
  use MemexWeb, :live_component
  alias Ecto.Changeset
  alias Memex.Contexts

  @impl true
  def update(%{context: context, current_user: current_user} = assigns, socket) do
    changeset = Contexts.change_context(context, current_user)

    socket =
      socket
      |> assign(assigns)
      |> assign(:changeset, changeset)

    {:ok, socket}
  end

  @impl true
  def handle_event(
        "validate",
        %{"context" => context_params},
        %{assigns: %{context: context, current_user: current_user}} = socket
      ) do
    changeset = context |> Contexts.change_context(context_params, current_user)

    changeset =
      case changeset |> Changeset.apply_action(:validate) do
        {:ok, _data} -> changeset
        {:error, changeset} -> changeset
      end

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
    socket =
      case Contexts.update_context(context, context_params, current_user) do
        {:ok, %{slug: slug}} ->
          socket
          |> put_flash(:info, gettext("%{slug} saved", slug: slug))
          |> push_navigate(to: return_to)

        {:error, %Changeset{} = changeset} ->
          assign(socket, :changeset, changeset)
      end

    {:noreply, socket}
  end

  defp save_context(
         %{assigns: %{return_to: return_to, current_user: current_user}} = socket,
         :new,
         context_params
       ) do
    socket =
      case Contexts.create_context(context_params, current_user) do
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
