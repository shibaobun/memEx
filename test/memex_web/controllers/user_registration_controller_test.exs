defmodule MemexWeb.UserRegistrationControllerTest do
  @moduledoc """
  Tests user registration
  """

  use MemexWeb.ConnCase, async: true

  @moduletag :user_registration_controller_test

  describe "GET /users/register" do
    test "renders registration page", %{conn: conn} do
      conn = get(conn, ~p"/users/register")
      response = html_response(conn, 200)
      assert response =~ "register"
      assert response =~ "log in"
    end

    test "redirects if already logged in", %{conn: conn} do
      conn = conn |> log_in_user(user_fixture()) |> get(~p"/users/register")
      assert redirected_to(conn) == "/"
    end
  end

  describe "POST /users/register" do
    @tag :capture_log
    test "creates account and logs the user in", %{conn: conn} do
      email = unique_user_email()

      conn =
        post(conn, ~p"/users/register", %{
          user: valid_user_attributes(email: email)
        })

      assert get_session(conn, :phoenix_flash) == %{
               "info" => "please check your email to verify your account"
             }

      assert redirected_to(conn) =~ "/"
    end

    test "render errors for invalid data", %{conn: conn} do
      conn =
        post(conn, ~p"/users/register", %{
          user: %{email: "with spaces", password: "too short"}
        })

      response = html_response(conn, 200)
      assert response =~ "register"
      assert response =~ "must have the @ sign and no spaces"
      assert response =~ "should be at least 12 character"
    end
  end
end
