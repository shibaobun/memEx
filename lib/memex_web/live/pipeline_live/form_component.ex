defmodule MemexWeb.PipelineLive.FormComponent do
  use MemexWeb, :live_component

  alias Memex.Pipelines

  @impl true
  def update(%{pipeline: pipeline} = assigns, socket) do
    changeset = Pipelines.change_pipeline(pipeline)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"pipeline" => pipeline_params}, socket) do
    changeset =
      socket.assigns.pipeline
      |> Pipelines.change_pipeline(pipeline_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"pipeline" => pipeline_params}, socket) do
    save_pipeline(socket, socket.assigns.action, pipeline_params)
  end

  defp save_pipeline(socket, :edit, pipeline_params) do
    case Pipelines.update_pipeline(socket.assigns.pipeline, pipeline_params) do
      {:ok, _pipeline} ->
        {:noreply,
         socket
         |> put_flash(:info, "Pipeline updated successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_pipeline(socket, :new, pipeline_params) do
    case Pipelines.create_pipeline(pipeline_params) do
      {:ok, _pipeline} ->
        {:noreply,
         socket
         |> put_flash(:info, "Pipeline created successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
