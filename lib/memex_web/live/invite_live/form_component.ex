defmodule MemexWeb.InviteLive.FormComponent do
  @moduledoc """
  Livecomponent that can update or create an Memex.Invites.Invite
  """

  use MemexWeb, :live_component
  alias Ecto.Changeset
  alias Memex.{Accounts.User, Invites, Invites.Invite}
  alias Phoenix.LiveView.Socket

  @impl true
  @spec update(
          %{:invite => Invite.t(), :current_user => User.t(), optional(any) => any},
          Socket.t()
        ) :: {:ok, Socket.t()}
  def update(%{invite: invite} = assigns, socket) do
    {:ok, socket |> assign(assigns) |> assign(:changeset, Invites.change_invite(invite))}
  end

  @impl true
  def handle_event(
        "validate",
        %{"invite" => invite_params},
        %{assigns: %{invite: invite}} = socket
      ) do
    {:noreply, socket |> assign(:changeset, invite |> Invites.change_invite(invite_params))}
  end

  def handle_event("save", %{"invite" => invite_params}, %{assigns: %{action: action}} = socket) do
    save_invite(socket, action, invite_params)
  end

  defp save_invite(
         %{assigns: %{current_user: current_user, invite: invite, return_to: return_to}} = socket,
         :edit,
         invite_params
       ) do
    socket =
      case invite |> Invites.update_invite(invite_params, current_user) do
        {:ok, %{name: invite_name}} ->
          prompt =
            dgettext("prompts", "%{invite_name} updated successfully", invite_name: invite_name)

          socket |> put_flash(:info, prompt) |> push_redirect(to: return_to)

        {:error, %Changeset{} = changeset} ->
          socket |> assign(:changeset, changeset)
      end

    {:noreply, socket}
  end

  defp save_invite(
         %{assigns: %{current_user: current_user, return_to: return_to}} = socket,
         :new,
         invite_params
       ) do
    socket =
      case current_user |> Invites.create_invite(invite_params) do
        {:ok, %{name: invite_name}} ->
          prompt =
            dgettext("prompts", "%{invite_name} created successfully", invite_name: invite_name)

          socket |> put_flash(:info, prompt) |> push_redirect(to: return_to)

        {:error, %Changeset{} = changeset} ->
          socket |> assign(changeset: changeset)
      end

    {:noreply, socket}
  end
end
