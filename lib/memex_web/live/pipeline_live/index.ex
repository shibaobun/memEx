defmodule MemexWeb.PipelineLive.Index do
  use MemexWeb, :live_view
  alias Memex.{Accounts.User, Pipelines, Pipelines.Pipeline}

  @impl true
  def mount(%{"search" => search}, _session, socket) do
    {:ok, socket |> assign(search: search) |> display_pipelines()}
  end

  def mount(_params, _session, socket) do
    {:ok, socket |> assign(search: nil) |> display_pipelines()}
  end

  @impl true
  def handle_params(params, _url, %{assigns: %{live_action: live_action}} = socket) do
    {:noreply, apply_action(socket, live_action, params)}
  end

  defp apply_action(%{assigns: %{current_user: current_user}} = socket, :edit, %{"id" => id}) do
    %{title: title} = pipeline = Pipelines.get_pipeline!(id, current_user)

    socket
    |> assign(page_title: gettext("edit %{title}", title: title))
    |> assign(pipeline: pipeline)
  end

  defp apply_action(%{assigns: %{current_user: %{id: current_user_id}}} = socket, :new, _params) do
    socket
    |> assign(page_title: gettext("new pipeline"))
    |> assign(pipeline: %Pipeline{user_id: current_user_id})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(page_title: gettext("pipelines"))
    |> assign(search: nil)
    |> assign(pipeline: nil)
    |> display_pipelines()
  end

  defp apply_action(socket, :search, %{"search" => search}) do
    socket
    |> assign(page_title: gettext("pipelines"))
    |> assign(search: search)
    |> assign(pipeline: nil)
    |> display_pipelines()
  end

  @impl true
  def handle_event("delete", %{"id" => id}, %{assigns: %{current_user: current_user}} = socket) do
    pipeline = Pipelines.get_pipeline!(id, current_user)
    {:ok, %{title: title}} = Pipelines.delete_pipeline(pipeline, current_user)

    socket =
      socket
      |> assign(pipelines: Pipelines.list_pipelines(current_user))
      |> put_flash(:info, gettext("%{title} deleted", title: title))

    {:noreply, socket}
  end

  @impl true
  def handle_event("search", %{"search" => %{"search_term" => ""}}, socket) do
    {:noreply, socket |> push_patch(to: Routes.pipeline_index_path(Endpoint, :index))}
  end

  def handle_event("search", %{"search" => %{"search_term" => search_term}}, socket) do
    {:noreply,
     socket |> push_patch(to: Routes.pipeline_index_path(Endpoint, :search, search_term))}
  end

  defp display_pipelines(%{assigns: %{current_user: current_user, search: search}} = socket)
       when not (current_user |> is_nil()) do
    socket |> assign(pipelines: Pipelines.list_pipelines(search, current_user))
  end

  defp display_pipelines(%{assigns: %{search: search}} = socket) do
    socket |> assign(pipelines: Pipelines.list_public_pipelines(search))
  end

  @spec is_owner_or_admin?(Pipeline.t(), User.t()) :: boolean()
  defp is_owner_or_admin?(%{user_id: user_id}, %{id: user_id}), do: true
  defp is_owner_or_admin?(_context, %{role: :admin}), do: true
  defp is_owner_or_admin?(_context, _other_user), do: false

  @spec is_owner?(Pipeline.t(), User.t()) :: boolean()
  defp is_owner?(%{user_id: user_id}, %{id: user_id}), do: true
  defp is_owner?(_context, _other_user), do: false
end
