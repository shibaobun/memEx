defmodule MemexWeb.InviteLive.FormComponent do
  @moduledoc """
  Livecomponent that can update or create an Memex.Accounts.Invite
  """

  use MemexWeb, :live_component
  alias Ecto.Changeset
  alias Memex.Accounts.{Invite, Invites, User}
  alias Phoenix.LiveView.Socket

  @impl true
  @spec update(
          %{:invite => Invite.t(), :current_user => User.t(), optional(any) => any},
          Socket.t()
        ) :: {:ok, Socket.t()}
  def update(%{invite: _invite} = assigns, socket) do
    {:ok, socket |> assign(assigns) |> assign_changeset(%{})}
  end

  @impl true
  def handle_event("validate", %{"invite" => invite_params}, socket) do
    {:noreply, socket |> assign_changeset(invite_params, :validate)}
  end

  def handle_event("save", %{"invite" => invite_params}, %{assigns: %{action: action}} = socket) do
    save_invite(socket, action, invite_params)
  end

  defp assign_changeset(
         %{assigns: %{action: action, current_user: user, invite: invite}} = socket,
         invite_params,
         changeset_action \\ nil
       ) do
    default_action =
      case action do
        :new -> :insert
        :edit -> :update
      end

    changeset =
      case default_action do
        :insert -> Invite.create_changeset(user, "example_token", invite_params)
        :update -> invite |> Invite.update_changeset(invite_params)
      end

    changeset =
      case changeset |> Changeset.apply_action(changeset_action || default_action) do
        {:ok, _data} -> changeset
        {:error, changeset} -> changeset
      end

    socket |> assign(:changeset, changeset)
  end

  defp save_invite(
         %{assigns: %{current_user: current_user, invite: invite, return_to: return_to}} = socket,
         :edit,
         invite_params
       ) do
    socket =
      case invite |> Invites.update_invite(invite_params, current_user) do
        {:ok, %{name: invite_name}} ->
          prompt = dgettext("prompts", "%{name} updated successfully", name: invite_name)
          socket |> put_flash(:info, prompt) |> push_navigate(to: return_to)

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
          prompt = dgettext("prompts", "%{name} created successfully", name: invite_name)
          socket |> put_flash(:info, prompt) |> push_navigate(to: return_to)

        {:error, %Changeset{} = changeset} ->
          socket |> assign(changeset: changeset)
      end

    {:noreply, socket}
  end
end
