defmodule MemexWeb.StepLive.FormComponent do
  use MemexWeb, :live_component
  alias Ecto.Changeset
  alias Memex.Pipelines.Steps

  @impl true
  def update(%{step: step, current_user: current_user, pipeline: _pipeline} = assigns, socket) do
    changeset = Steps.change_step(step, current_user)

    socket =
      socket
      |> assign(assigns)
      |> assign(:changeset, changeset)

    {:ok, socket}
  end

  @impl true
  def handle_event(
        "validate",
        %{"step" => step_params},
        %{assigns: %{step: step, current_user: current_user}} = socket
      ) do
    changeset = step |> Steps.change_step(step_params, current_user)

    changeset =
      case changeset |> Changeset.apply_action(:validate) do
        {:ok, _data} -> changeset
        {:error, changeset} -> changeset
      end

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"step" => step_params}, %{assigns: %{action: action}} = socket) do
    save_step(socket, action, step_params)
  end

  defp save_step(
         %{assigns: %{step: step, return_to: return_to, current_user: current_user}} = socket,
         :edit_step,
         step_params
       ) do
    socket =
      case Steps.update_step(step, step_params, current_user) do
        {:ok, %{title: title}} ->
          socket
          |> put_flash(:info, gettext("%{title} saved", title: title))
          |> push_navigate(to: return_to)

        {:error, %Changeset{} = changeset} ->
          assign(socket, :changeset, changeset)
      end

    {:noreply, socket}
  end

  defp save_step(
         %{
           assigns: %{
             step: %{position: position},
             return_to: return_to,
             current_user: current_user,
             pipeline: pipeline
           }
         } = socket,
         :add_step,
         step_params
       ) do
    socket =
      case Steps.create_step(step_params, position, pipeline, current_user) do
        {:ok, %{title: title}} ->
          socket
          |> put_flash(:info, gettext("%{title} created", title: title))
          |> push_navigate(to: return_to)

        {:error, %Changeset{} = changeset} ->
          assign(socket, changeset: changeset)
      end

    {:noreply, socket}
  end
end
