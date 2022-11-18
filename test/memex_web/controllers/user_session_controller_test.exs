defmodule MemexWeb.UserSessionControllerTest do
  @moduledoc """
  Tests the user session controller
  """

  use MemexWeb.ConnCase, async: true
  import MemexWeb.Gettext

  @moduletag :user_session_controller_test

  setup %{conn: conn} do
    [current_user: user_fixture() |> confirm_user(), conn: conn]
  end

  describe "GET /users/log_in" do
    test "renders log in page", %{conn: conn} do
      conn = get(conn, Routes.user_session_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ dgettext("actions", "log in")
    end

    test "redirects if already logged in", %{conn: conn, current_user: current_user} do
      conn = conn |> log_in_user(current_user) |> get(Routes.user_session_path(conn, :new))
      assert redirected_to(conn) == "/"
    end
  end

  describe "POST /users/log_in" do
    test "logs the user in", %{conn: conn, current_user: current_user} do
      conn =
        post(conn, Routes.user_session_path(conn, :create), %{
          "user" => %{"email" => current_user.email, "password" => valid_user_password()}
        })

      assert get_session(conn, :user_token)
      assert redirected_to(conn) =~ "/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, "/")
      response = html_response(conn, 200)
      assert response =~ current_user.email
      assert response =~ dgettext("prompts", "are you sure you want to log out?")
    end

    test "logs the user in with remember me", %{conn: conn, current_user: current_user} do
      conn =
        post(conn, Routes.user_session_path(conn, :create), %{
          "user" => %{
            "email" => current_user.email,
            "password" => valid_user_password(),
            "remember_me" => "true"
          }
        })

      assert conn.resp_cookies["_memex_web_user_remember_me"]
      assert redirected_to(conn) =~ "/"
    end

    test "logs the user in with return to", %{conn: conn, current_user: current_user} do
      conn =
        conn
        |> init_test_session(user_return_to: "/foo/bar")
        |> post(Routes.user_session_path(conn, :create), %{
          "user" => %{
            "email" => current_user.email,
            "password" => valid_user_password()
          }
        })

      assert redirected_to(conn) == "/foo/bar"
    end

    test "emits error message with invalid credentials",
         %{conn: conn, current_user: current_user} do
      conn =
        post(conn, Routes.user_session_path(conn, :create), %{
          "user" => %{"email" => current_user.email, "password" => "bad"}
        })

      response = html_response(conn, 200)
      assert response =~ dgettext("actions", "log in")
      assert response =~ dgettext("errors", "Invalid email or password")
    end
  end

  describe "DELETE /users/log_out" do
    test "logs the user out", %{conn: conn, current_user: current_user} do
      conn = conn |> log_in_user(current_user) |> delete(Routes.user_session_path(conn, :delete))
      assert redirected_to(conn) == "/"
      refute get_session(conn, :user_token)
      assert get_flash(conn, :info) =~ gettext("Logged out successfully")
    end

    test "succeeds even if the user is not logged in", %{conn: conn} do
      conn = delete(conn, Routes.user_session_path(conn, :delete))
      assert redirected_to(conn) == "/"
      refute get_session(conn, :user_token)
      assert get_flash(conn, :info) =~ gettext("Logged out successfully")
    end
  end
end
