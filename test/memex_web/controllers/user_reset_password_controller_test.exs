defmodule MemexWeb.UserResetPasswordControllerTest do
  @moduledoc """
  Tests the user reset password controller
  """

  use MemexWeb.ConnCase, async: true
  alias Memex.{Accounts, Repo}

  @moduletag :user_reset_password_controller_test

  setup do
    %{user: user_fixture()}
  end

  describe "GET /users/reset_password" do
    test "renders the reset password page", %{conn: conn} do
      conn = get(conn, ~p"/users/reset_password")
      response = html_response(conn, 200)
      assert response =~ "forgot your password?"
    end
  end

  describe "POST /users/reset_password" do
    @tag :capture_log
    test "sends a new reset password token", %{conn: conn, user: user} do
      conn = post(conn, ~p"/users/reset_password", %{user: %{email: user.email}})
      assert redirected_to(conn) == ~p"/"

      assert conn.assigns.flash["info"] =~
               "if your email is in our system, you will receive instructions to reset your password shortly."

      assert Repo.get_by!(Accounts.UserToken, user_id: user.id).context == "reset_password"
    end

    test "does not send reset password token if email is invalid", %{conn: conn} do
      conn = post(conn, ~p"/users/reset_password", %{user: %{email: "unknown@example.com"}})
      assert redirected_to(conn) == ~p"/"

      assert conn.assigns.flash["info"] =~
               "if your email is in our system, you will receive instructions to reset your password shortly."

      assert Repo.all(Accounts.UserToken) == []
    end
  end

  describe "GET /users/reset_password/:token" do
    setup %{user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_reset_password_instructions(user, url)
        end)

      %{token: token}
    end

    test "renders reset password", %{conn: conn, token: token} do
      conn = get(conn, ~p"/users/reset_password/#{token}")
      assert html_response(conn, 200) =~ "reset password"
    end

    test "does not render reset password with invalid token", %{conn: conn} do
      conn = get(conn, ~p"/users/reset_password/oops")
      assert redirected_to(conn) == ~p"/"
      assert conn.assigns.flash["error"] =~ "reset password link is invalid or it has expired"
    end
  end

  describe "PUT /users/reset_password/:token" do
    setup %{user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_reset_password_instructions(user, url)
        end)

      %{token: token}
    end

    test "resets password once", %{conn: conn, user: user, token: token} do
      conn =
        put(conn, ~p"/users/reset_password/#{token}", %{
          user: %{
            password: "new valid password",
            password_confirmation: "new valid password"
          }
        })

      assert redirected_to(conn) == ~p"/users/log_in"
      refute get_session(conn, :user_token)
      assert conn.assigns.flash["info"] =~ "password reset successfully"
      assert Accounts.get_user_by_email_and_password(user.email, "new valid password")
    end

    test "does not reset password on invalid data", %{conn: conn, token: token} do
      conn =
        put(conn, ~p"/users/reset_password/#{token}", %{
          user: %{
            password: "too short",
            password_confirmation: "does not match"
          }
        })

      response = html_response(conn, 200)
      assert response =~ "reset password"
      assert response =~ "should be at least 12 character(s)"
      assert response =~ "does not match password"
    end

    test "does not reset password with invalid token", %{conn: conn} do
      conn = put(conn, ~p"/users/reset_password/oops")
      assert redirected_to(conn) == ~p"/"
      assert conn.assigns.flash["error"] =~ "reset password link is invalid or it has expired"
    end
  end
end
