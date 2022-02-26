defmodule LokalWeb.UserSettingsController do
  use LokalWeb, :controller
  import LokalWeb.Gettext
  alias Lokal.Accounts
  alias LokalWeb.{PageLive, UserAuth}

  plug :assign_email_and_password_changesets

  def edit(conn, _params) do
    render(conn, "edit.html", page_title: gettext("Settings"))
  end

  def update(conn, %{"action" => "update_email"} = params) do
    %{"current_password" => password, "user" => user_params} = params
    user = conn.assigns.current_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_update_email_instructions(
          applied_user,
          user.email,
          &Routes.user_settings_url(conn, :confirm_email, &1)
        )

        conn
        |> put_flash(
          :info,
          dgettext(
            "prompts",
            "A link to confirm your email change has been sent to the new address."
          )
        )
        |> redirect(to: Routes.user_settings_path(conn, :edit))

      {:error, changeset} ->
        render(conn, "edit.html", email_changeset: changeset)
    end
  end

  def update(conn, %{"action" => "update_password"} = params) do
    %{"current_password" => password, "user" => user_params} = params
    user = conn.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, dgettext("prompts", "Password updated successfully."))
        |> put_session(:user_return_to, Routes.user_settings_path(conn, :edit))
        |> UserAuth.log_in_user(user)

      {:error, changeset} ->
        render(conn, "edit.html", password_changeset: changeset)
    end
  end

  def confirm_email(conn, %{"token" => token}) do
    case Accounts.update_user_email(conn.assigns.current_user, token) do
      :ok ->
        conn
        |> put_flash(:info, dgettext("prompts", "Email changed successfully."))
        |> redirect(to: Routes.user_settings_path(conn, :edit))

      :error ->
        conn
        |> put_flash(
          :error,
          dgettext("errors", "Email change link is invalid or it has expired.")
        )
        |> redirect(to: Routes.user_settings_path(conn, :edit))
    end
  end

  def delete(%{assigns: %{current_user: current_user}} = conn, %{"id" => user_id}) do
    if user_id == current_user.id do
      current_user |> Accounts.delete_user!(current_user)

      conn
      |> put_flash(:error, dgettext("prompts", "Your account has been deleted"))
      |> redirect(to: Routes.live_path(conn, PageLive))
    else
      conn
      |> put_flash(:error, dgettext("errors", "Unable to delete user"))
      |> redirect(to: Routes.user_settings_path(conn, :edit))
    end
  end

  defp assign_email_and_password_changesets(conn, _opts) do
    user = conn.assigns.current_user

    conn
    |> assign(:email_changeset, Accounts.change_user_email(user))
    |> assign(:password_changeset, Accounts.change_user_password(user))
  end
end
