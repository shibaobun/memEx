defmodule MemexWeb.UserSettingsControllerTest do
  @moduledoc """
  Tests the user settings controller
  """

  use MemexWeb.ConnCase, async: true
  import MemexWeb.Gettext
  alias Memex.Accounts

  @moduletag :user_settings_controller_test

  setup :register_and_log_in_user

  describe "GET /users/settings" do
    test "renders settings page", %{conn: conn} do
      conn = get(conn, Routes.user_settings_path(conn, :edit))
      response = html_response(conn, 200)
      assert response =~ gettext("settings")
    end

    test "redirects if user is not logged in" do
      conn = build_conn()
      conn = get(conn, Routes.user_settings_path(conn, :edit))
      assert redirected_to(conn) == Routes.user_session_path(conn, :new)
    end
  end

  describe "PUT /users/settings (change password form)" do
    test "updates the user password and resets tokens",
         %{conn: conn, current_user: current_user} do
      new_password_conn =
        put(conn, Routes.user_settings_path(conn, :update), %{
          "action" => "update_password",
          "current_password" => valid_user_password(),
          "user" => %{
            "password" => "new valid password",
            "password_confirmation" => "new valid password"
          }
        })

      assert redirected_to(new_password_conn) == Routes.user_settings_path(conn, :edit)
      assert get_session(new_password_conn, :user_token) != get_session(conn, :user_token)

      assert get_flash(new_password_conn, :info) =~
               dgettext("actions", "password updated successfully")

      assert Accounts.get_user_by_email_and_password(current_user.email, "new valid password")
    end

    test "does not update password on invalid data", %{conn: conn} do
      old_password_conn =
        put(conn, Routes.user_settings_path(conn, :update), %{
          "action" => "update_password",
          "current_password" => "invalid",
          "user" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      response = html_response(old_password_conn, 200)
      assert response =~ gettext("settings")
      assert response =~ dgettext("errors", "should be at least 12 character(s)")
      assert response =~ dgettext("errors", "does not match password")
      assert response =~ dgettext("errors", "is not valid")

      assert get_session(old_password_conn, :user_token) == get_session(conn, :user_token)
    end
  end

  describe "PUT /users/settings (change email form)" do
    @tag :capture_log
    test "updates the user email", %{conn: conn, current_user: current_user} do
      conn =
        put(conn, Routes.user_settings_path(conn, :update), %{
          "action" => "update_email",
          "current_password" => valid_user_password(),
          "user" => %{"email" => unique_user_email()}
        })

      assert redirected_to(conn) == Routes.user_settings_path(conn, :edit)

      assert get_flash(conn, :info) =~
               dgettext(
                 "prompts",
                 "a link to confirm your email change has been sent to the new address."
               )

      assert Accounts.get_user_by_email(current_user.email)
    end

    test "does not update email on invalid data", %{conn: conn} do
      conn =
        put(conn, Routes.user_settings_path(conn, :update), %{
          "action" => "update_email",
          "current_password" => "invalid",
          "user" => %{"email" => "with spaces"}
        })

      response = html_response(conn, 200)
      assert response =~ gettext("settings")
      assert response =~ dgettext("errors", "must have the @ sign and no spaces")
      assert response =~ dgettext("errors", "is not valid")
    end
  end

  describe "GET /users/settings/confirm_email/:token" do
    setup %{current_user: current_user} do
      email = unique_user_email()

      token =
        extract_user_token(fn url ->
          Accounts.deliver_update_email_instructions(
            %{current_user | email: email},
            current_user.email,
            url
          )
        end)

      %{token: token, email: email}
    end

    test "updates the user email once",
         %{conn: conn, current_user: current_user, token: token, email: email} do
      conn = get(conn, Routes.user_settings_path(conn, :confirm_email, token))
      assert redirected_to(conn) == Routes.user_settings_path(conn, :edit)
      assert get_flash(conn, :info) =~ dgettext("prompts", "email changed successfully")
      refute Accounts.get_user_by_email(current_user.email)
      assert Accounts.get_user_by_email(email)

      conn = get(conn, Routes.user_settings_path(conn, :confirm_email, token))
      assert redirected_to(conn) == Routes.user_settings_path(conn, :edit)

      assert get_flash(conn, :error) =~
               dgettext("errors", "email change link is invalid or it has expired")
    end

    test "does not update email with invalid token", %{conn: conn, current_user: current_user} do
      conn = get(conn, Routes.user_settings_path(conn, :confirm_email, "oops"))
      assert redirected_to(conn) == Routes.user_settings_path(conn, :edit)

      assert get_flash(conn, :error) =~
               dgettext("errors", "email change link is invalid or it has expired")

      assert Accounts.get_user_by_email(current_user.email)
    end

    test "redirects if user is not logged in", %{token: token} do
      conn = build_conn()
      conn = get(conn, Routes.user_settings_path(conn, :confirm_email, token))
      assert redirected_to(conn) == Routes.user_session_path(conn, :new)
    end
  end
end
