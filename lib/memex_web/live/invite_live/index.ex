defmodule MemexWeb.InviteLive.Index do
  @moduledoc """
  Liveview to show a Memex.Accounts.Invite index
  """

  use MemexWeb, :live_view
  import MemexWeb.Components.{InviteCard, UserCard}
  alias Memex.Accounts
  alias Memex.Accounts.{Invite, Invites}
  alias MemexWeb.{Endpoint, HomeLive}
  alias Phoenix.LiveView.JS

  @impl true
  def mount(_params, _session, %{assigns: %{current_user: current_user}} = socket) do
    socket =
      if current_user |> Map.get(:role) == :admin do
        socket |> display_invites()
      else
        prompt = dgettext("errors", "you are not authorized to view this page")
        return_to = Routes.live_path(Endpoint, HomeLive)
        socket |> put_flash(:error, prompt) |> push_redirect(to: return_to)
      end

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, %{assigns: %{live_action: live_action}} = socket) do
    {:noreply, socket |> apply_action(live_action, params)}
  end

  defp apply_action(%{assigns: %{current_user: current_user}} = socket, :edit, %{"id" => id}) do
    socket
    |> assign(page_title: gettext("edit invite"), invite: Invites.get_invite!(id, current_user))
  end

  defp apply_action(socket, :new, _params) do
    socket |> assign(page_title: gettext("new invite"), invite: %Invite{})
  end

  defp apply_action(socket, :index, _params) do
    socket |> assign(page_title: gettext("invites"), invite: nil)
  end

  @impl true
  def handle_event(
        "delete_invite",
        %{"id" => id},
        %{assigns: %{current_user: current_user}} = socket
      ) do
    %{name: invite_name} =
      id |> Invites.get_invite!(current_user) |> Invites.delete_invite!(current_user)

    prompt = dgettext("prompts", "%{invite_name} deleted succesfully", invite_name: invite_name)
    {:noreply, socket |> put_flash(:info, prompt) |> display_invites()}
  end

  def handle_event(
        "set_unlimited",
        %{"id" => id},
        %{assigns: %{current_user: current_user}} = socket
      ) do
    socket =
      Invites.get_invite!(id, current_user)
      |> Invites.update_invite(%{uses_left: nil}, current_user)
      |> case do
        {:ok, %{name: invite_name}} ->
          prompt =
            dgettext("prompts", "%{invite_name} updated succesfully", invite_name: invite_name)

          socket |> put_flash(:info, prompt) |> display_invites()

        {:error, changeset} ->
          socket |> put_flash(:error, changeset |> changeset_errors())
      end

    {:noreply, socket}
  end

  def handle_event(
        "enable_invite",
        %{"id" => id},
        %{assigns: %{current_user: current_user}} = socket
      ) do
    socket =
      Invites.get_invite!(id, current_user)
      |> Invites.update_invite(%{uses_left: nil, disabled_at: nil}, current_user)
      |> case do
        {:ok, %{name: invite_name}} ->
          prompt =
            dgettext("prompts", "%{invite_name} enabled succesfully", invite_name: invite_name)

          socket |> put_flash(:info, prompt) |> display_invites()

        {:error, changeset} ->
          socket |> put_flash(:error, changeset |> changeset_errors())
      end

    {:noreply, socket}
  end

  def handle_event(
        "disable_invite",
        %{"id" => id},
        %{assigns: %{current_user: current_user}} = socket
      ) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    socket =
      Invites.get_invite!(id, current_user)
      |> Invites.update_invite(%{uses_left: 0, disabled_at: now}, current_user)
      |> case do
        {:ok, %{name: invite_name}} ->
          prompt =
            dgettext("prompts", "%{invite_name} disabled succesfully", invite_name: invite_name)

          socket |> put_flash(:info, prompt) |> display_invites()

        {:error, changeset} ->
          socket |> put_flash(:error, changeset |> changeset_errors())
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("copy_to_clipboard", _params, socket) do
    prompt = dgettext("prompts", "copied to clipboard")
    {:noreply, socket |> put_flash(:info, prompt)}
  end

  @impl true
  def handle_event(
        "delete_user",
        %{"id" => id},
        %{assigns: %{current_user: current_user}} = socket
      ) do
    %{email: user_email} = Accounts.get_user!(id) |> Accounts.delete_user!(current_user)

    prompt = dgettext("prompts", "%{user_email} deleted succesfully", user_email: user_email)

    {:noreply, socket |> put_flash(:info, prompt) |> display_invites()}
  end

  defp display_invites(%{assigns: %{current_user: current_user}} = socket) do
    invites = Invites.list_invites(current_user)
    all_users = Accounts.list_all_users_by_role(current_user)

    admins =
      all_users
      |> Map.get(:admin, [])
      |> Enum.reject(fn %{id: user_id} -> user_id == current_user.id end)

    users = all_users |> Map.get(:user, [])
    socket |> assign(invites: invites, admins: admins, users: users)
  end
end
