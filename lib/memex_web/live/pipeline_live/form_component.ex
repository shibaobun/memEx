defmodule MemexWeb.PipelineLive.FormComponent do
  use MemexWeb, :live_component

  alias Memex.Pipelines

  @impl true
  def update(%{pipeline: pipeline, current_user: current_user} = assigns, socket) do
    changeset = Pipelines.change_pipeline(pipeline, current_user)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event(
        "validate",
        %{"pipeline" => pipeline_params},
        %{assigns: %{pipeline: pipeline, current_user: current_user}} = socket
      ) do
    changeset =
      pipeline
      |> Pipelines.change_pipeline(pipeline_params, current_user)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event(
        "save",
        %{"pipeline" => pipeline_params},
        %{assigns: %{action: action}} = socket
      ) do
    save_pipeline(socket, action, pipeline_params)
  end

  defp save_pipeline(
         %{assigns: %{pipeline: pipeline, return_to: return_to, current_user: current_user}} =
           socket,
         :edit,
         pipeline_params
       ) do
    case Pipelines.update_pipeline(pipeline, pipeline_params, current_user) do
      {:ok, %{title: title}} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("%{title} saved", title: title))
         |> push_navigate(to: return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_pipeline(
         %{assigns: %{return_to: return_to, current_user: current_user}} = socket,
         :new,
         pipeline_params
       ) do
    case Pipelines.create_pipeline(pipeline_params, current_user) do
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
