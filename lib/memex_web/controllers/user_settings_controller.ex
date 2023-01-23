defmodule MemexWeb.UserSettingsController do
  use MemexWeb, :controller
  import MemexWeb.Gettext
  alias Memex.Accounts
  alias MemexWeb.{HomeLive, UserAuth}

  plug :assign_email_and_password_changesets

  def edit(conn, _params) do
    render(conn, "edit.html", page_title: gettext("Settings"))
  end

  def update(%{assigns: %{current_user: user}} = conn, %{
        "action" => "update_email",
        "current_password" => password,
        "user" => user_params
      }) do
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
        conn |> render("edit.html", email_changeset: changeset)
    end
  end

  def update(%{assigns: %{current_user: user}} = conn, %{
        "action" => "update_password",
        "current_password" => password,
        "user" => user_params
      }) do
    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, dgettext("prompts", "Password updated successfully."))
        |> put_session(:user_return_to, Routes.user_settings_path(conn, :edit))
        |> UserAuth.log_in_user(user)

      {:error, changeset} ->
        conn |> render("edit.html", password_changeset: changeset)
    end
  end

  def update(
        %{assigns: %{current_user: user}} = conn,
        %{"action" => "update_locale", "user" => %{"locale" => locale}}
      ) do
    case Accounts.update_user_locale(user, locale) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, dgettext("prompts", "language updated successfully."))
        |> redirect(to: Routes.user_settings_path(conn, :edit))

      {:error, changeset} ->
        conn |> render("edit.html", locale_changeset: changeset)
    end
  end

  def confirm_email(%{assigns: %{current_user: user}} = conn, %{"token" => token}) do
    case Accounts.update_user_email(user, token) do
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
      |> redirect(to: Routes.live_path(conn, HomeLive))
    else
      conn
      |> put_flash(:error, dgettext("errors", "Unable to delete user"))
      |> redirect(to: Routes.user_settings_path(conn, :edit))
    end
  end

  defp assign_email_and_password_changesets(%{assigns: %{current_user: user}} = conn, _opts) do
    conn
    |> assign(:email_changeset, Accounts.change_user_email(user))
    |> assign(:password_changeset, Accounts.change_user_password(user))
    |> assign(:locale_changeset, Accounts.change_user_locale(user))
  end
end
