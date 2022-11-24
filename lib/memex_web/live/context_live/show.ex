defmodule MemexWeb.ContextLive.Show do
  use MemexWeb, :live_view

  alias Memex.Contexts

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(
        %{"id" => id},
        _,
        %{assigns: %{live_action: live_action, current_user: current_user}} = socket
      ) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(live_action))
     |> assign(:context, Contexts.get_context!(id, current_user))}
  end

  @impl true
  def handle_event(
        "delete",
        _params,
        %{assigns: %{context: context, current_user: current_user}} = socket
      ) do
    {:ok, %{title: title}} = Contexts.delete_context(context, current_user)

    socket =
      socket
      |> put_flash(:info, gettext("%{title} deleted", title: title))
      |> push_navigate(to: Routes.context_index_path(Endpoint, :index))

    {:noreply, socket}
  end

  defp page_title(:show), do: gettext("show context")
  defp page_title(:edit), do: gettext("edit context")
end
