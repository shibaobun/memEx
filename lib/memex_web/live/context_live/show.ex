defmodule MemexWeb.ContextLive.Show do
  use MemexWeb, :live_view
  alias Memex.Contexts

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(
        %{"slug" => slug},
        _params,
        %{assigns: %{live_action: live_action, current_user: current_user}} = socket
      ) do
    context =
      case Contexts.get_context_by_slug(slug, current_user) do
        nil -> raise MemexWeb.NotFoundError, gettext("%{slug} could not be found", slug: slug)
        context -> context
      end

    socket =
      socket
      |> assign(:page_title, page_title(live_action, context))
      |> assign(:context, context)

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "delete",
        _params,
        %{assigns: %{context: context, current_user: current_user}} = socket
      ) do
    {:ok, %{slug: slug}} = Contexts.delete_context(context, current_user)

    socket =
      socket
      |> put_flash(:info, gettext("%{slug} deleted", slug: slug))
      |> push_navigate(to: Routes.context_index_path(Endpoint, :index))

    {:noreply, socket}
  end

  defp page_title(:show, %{slug: slug}), do: slug
  defp page_title(:edit, %{slug: slug}), do: gettext("edit %{slug}", slug: slug)
end
