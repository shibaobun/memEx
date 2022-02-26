defmodule LokalWeb.UserRegistrationControllerTest do
  @moduledoc """
  Tests user registration
  """

  use LokalWeb.ConnCase, async: true
  import LokalWeb.Gettext

  @moduletag :user_registration_controller_test

  describe "GET /users/register" do
    test "renders registration page", %{conn: conn} do
      conn = get(conn, Routes.user_registration_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ dgettext("actions", "Register")
      assert response =~ dgettext("actions", "Log in")
    end

    test "redirects if already logged in", %{conn: conn} do
      conn = conn |> log_in_user(user_fixture()) |> get(Routes.user_registration_path(conn, :new))
      assert redirected_to(conn) == "/"
    end
  end

  describe "POST /users/register" do
    @tag :capture_log
    test "creates account and logs the user in", %{conn: conn} do
      email = unique_user_email()

      conn =
        post(conn, Routes.user_registration_path(conn, :create), %{
          "user" => valid_user_attributes(email: email)
        })

      assert get_session(conn, :phoenix_flash) == %{
               "info" => dgettext("prompts", "Please check your email to verify your account")
             }

      assert redirected_to(conn) =~ "/"
    end

    test "render errors for invalid data", %{conn: conn} do
      conn =
        post(conn, Routes.user_registration_path(conn, :create), %{
          "user" => %{"email" => "with spaces", "password" => "too short"}
        })

      response = html_response(conn, 200)
      assert response =~ gettext("Register")
      assert response =~ "must have the @ sign and no spaces"
      assert response =~ "should be at least 12 character"
    end
  end
end
