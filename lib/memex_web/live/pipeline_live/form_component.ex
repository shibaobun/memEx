defmodule MemexWeb.PipelineLive.FormComponent do
  use MemexWeb, :live_component
  alias Ecto.Changeset
  alias Memex.Pipelines

  @impl true
  def update(%{pipeline: pipeline, current_user: current_user} = assigns, socket) do
    changeset = Pipelines.change_pipeline(pipeline, current_user)

    socket =
      socket
      |> assign(assigns)
      |> assign(:changeset, changeset)

    {:ok, socket}
  end

  @impl true
  def handle_event(
        "validate",
        %{"pipeline" => pipeline_params},
        %{assigns: %{pipeline: pipeline, current_user: current_user}} = socket
      ) do
    changeset = pipeline |> Pipelines.change_pipeline(pipeline_params, current_user)

    changeset =
      case changeset |> Changeset.apply_action(:validate) do
        {:ok, _data} -> changeset
        {:error, changeset} -> changeset
      end

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
    socket =
      case Pipelines.update_pipeline(pipeline, pipeline_params, current_user) do
        {:ok, %{slug: slug}} ->
          socket
          |> put_flash(:info, gettext("%{slug} saved", slug: slug))
          |> push_navigate(to: return_to)

        {:error, %Changeset{} = changeset} ->
          assign(socket, :changeset, changeset)
      end

    {:noreply, socket}
  end

  defp save_pipeline(
         %{assigns: %{return_to: return_to, current_user: current_user}} = socket,
         :new,
         pipeline_params
       ) do
    socket =
      case Pipelines.create_pipeline(pipeline_params, current_user) do
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
