defmodule MemexWeb.ContextLive.Show do
  use MemexWeb, :live_view

  alias Memex.{Accounts.User, Contexts, Contexts.Context}

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
    context = Contexts.get_context!(id, current_user)

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
    {:ok, %{title: title}} = Contexts.delete_context(context, current_user)

    socket =
      socket
      |> put_flash(:info, gettext("%{title} deleted", title: title))
      |> push_navigate(to: Routes.context_index_path(Endpoint, :index))

    {:noreply, socket}
  end

  defp page_title(:show, %{title: title}), do: title
  defp page_title(:edit, %{title: title}), do: gettext("edit %{title}", title: title)

  @spec is_owner_or_admin?(Context.t(), User.t()) :: boolean()
  defp is_owner_or_admin?(%{user_id: user_id}, %{id: user_id}), do: true
  defp is_owner_or_admin?(_context, %{role: :admin}), do: true
  defp is_owner_or_admin?(_context, _other_user), do: false

  @spec is_owner?(Context.t(), User.t()) :: boolean()
  defp is_owner?(%{user_id: user_id}, %{id: user_id}), do: true
  defp is_owner?(_context, _other_user), do: false
end
