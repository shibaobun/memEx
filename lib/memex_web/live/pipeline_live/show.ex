defmodule MemexWeb.PipelineLive.Show do
  use MemexWeb, :live_view
  alias Memex.{Pipelines, Pipelines.Steps, Pipelines.Steps.Step}

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(
        %{"slug" => slug} = params,
        _url,
        %{assigns: %{current_user: current_user, live_action: live_action}} = socket
      ) do
    pipeline =
      case Pipelines.get_pipeline_by_slug(slug, current_user) do
        nil -> raise MemexWeb.NotFoundError, gettext("%{slug} could not be found", slug: slug)
        pipeline -> pipeline
      end

    socket =
      socket
      |> assign(:page_title, page_title(live_action, pipeline))
      |> assign(:pipeline, pipeline)
      |> assign(:steps, pipeline |> Steps.list_steps(current_user))
      |> apply_action(live_action, params)

    {:noreply, socket}
  end

  defp apply_action(socket, live_action, _params) when live_action in [:show, :edit] do
    socket
  end

  defp apply_action(
         %{
           assigns: %{
             steps: steps,
             pipeline: %{id: pipeline_id},
             current_user: %{id: current_user_id}
           }
         } = socket,
         :add_step,
         _params
       ) do
    socket
    |> assign(
      step: %Step{
        position: steps |> Enum.count(),
        pipeline_id: pipeline_id,
        user_id: current_user_id
      }
    )
  end

  defp apply_action(
         %{assigns: %{current_user: current_user}} = socket,
         :edit_step,
         %{"step_id" => step_id}
       ) do
    socket |> assign(step: step_id |> Steps.get_step!(current_user))
  end

  @impl true
  def handle_event(
        "delete",
        _params,
        %{assigns: %{pipeline: pipeline, current_user: current_user}} = socket
      ) do
    {:ok, %{slug: slug}} = Pipelines.delete_pipeline(pipeline, current_user)

    socket =
      socket
      |> put_flash(:info, gettext("%{slug} deleted", slug: slug))
      |> push_navigate(to: Routes.pipeline_index_path(Endpoint, :index))

    {:noreply, socket}
  end

  def handle_event(
        "delete_step",
        %{"step-id" => step_id},
        %{assigns: %{pipeline: %{slug: pipeline_slug}, current_user: current_user}} = socket
      ) do
    {:ok, %{title: title}} =
      step_id
      |> Steps.get_step!(current_user)
      |> Steps.delete_step(current_user)

    socket =
      socket
      |> put_flash(:info, gettext("%{title} deleted", title: title))
      |> push_patch(to: Routes.pipeline_show_path(Endpoint, :show, pipeline_slug))

    {:noreply, socket}
  end

  def handle_event(
        "reorder_step",
        %{"step-id" => step_id, "direction" => direction},
        %{assigns: %{pipeline: %{slug: pipeline_slug}, current_user: current_user}} = socket
      ) do
    direction = if direction == "up", do: :up, else: :down

    {:ok, _step} =
      step_id
      |> Steps.get_step!(current_user)
      |> Steps.reorder_step(direction, current_user)

    socket =
      socket
      |> push_patch(to: Routes.pipeline_show_path(Endpoint, :show, pipeline_slug))

    {:noreply, socket}
  end

  defp page_title(:show, %{slug: slug}), do: slug

  defp page_title(live_action, %{slug: slug}) when live_action in [:edit, :edit_step],
    do: gettext("edit %{slug}", slug: slug)

  defp page_title(:add_step, %{slug: slug}), do: gettext("add step to %{slug}", slug: slug)
end
