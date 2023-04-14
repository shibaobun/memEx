defmodule MemexWeb.UserConfirmationControllerTest do
  @moduledoc """
  Tests user confirmation
  """

  use MemexWeb.ConnCase, async: true
  alias Memex.{Accounts, Repo}

  @moduletag :user_confirmation_controller_test

  setup do
    %{user: user_fixture()}
  end

  describe "GET /users/confirm" do
    test "renders the confirmation page", %{conn: conn} do
      conn = get(conn, ~p"/users/confirm")
      response = html_response(conn, 200)
      assert response =~ "Resend confirmation instructions"
    end
  end

  describe "POST /users/confirm" do
    @tag :capture_log
    test "sends a new confirmation token", %{conn: conn, user: user} do
      conn =
        post(conn, ~p"/users/confirm", %{
          user: %{email: user.email}
        })

      assert redirected_to(conn) == "/"

      conn.assigns.flash["info"] =~
        "If your email is in our system and it has not been confirmed yet, you will receive an email with instructions shortly."

      assert Repo.get_by!(Accounts.UserToken, user_id: user.id).context == "confirm"
    end

    test "does not send confirmation token if User is confirmed", %{conn: conn, user: user} do
      Repo.update!(Accounts.User.confirm_changeset(user))

      conn =
        post(conn, ~p"/users/confirm", %{
          user: %{email: user.email}
        })

      assert redirected_to(conn) == "/"

      conn.assigns.flash["info"] =~
        "If your email is in our system and it has not been confirmed yet, you will receive an email with instructions shortly."
    end

    test "does not send confirmation token if email is invalid", %{conn: conn} do
      conn =
        post(conn, ~p"/users/confirm", %{
          user: %{email: "unknown@example.com"}
        })

      assert redirected_to(conn) == "/"

      conn.assigns.flash["info"] =~
        "If your email is in our system and it has not been confirmed yet, you will receive an email with instructions shortly."

      assert Repo.all(Accounts.UserToken) == []
    end
  end

  describe "GET /users/confirm/:token" do
    test "confirms the given token once", %{conn: conn, user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_confirmation_instructions(user, url)
        end)

      conn = get(conn, ~p"/users/confirm/#{token}")
      assert redirected_to(conn) == "/"

      conn.assigns.flash["info"] =~ "#{user.email} confirmed successfully"

      assert Accounts.get_user!(user.id).confirmed_at
      refute get_session(conn, :user_token)
      assert Repo.all(Accounts.UserToken) == []

      # When not logged in
      conn = get(conn, ~p"/users/confirm/#{token}")
      assert redirected_to(conn) == "/"
      conn.assigns.flash["error"] =~ "User confirmation link is invalid or it has expired"

      # When logged in
      conn =
        build_conn()
        |> log_in_user(user)
        |> get(~p"/users/confirm/#{token}")

      assert redirected_to(conn) == "/"
      refute conn.assigns.flash["error"]
    end

    test "does not confirm email with invalid token", %{conn: conn, user: user} do
      conn = get(conn, ~p"/users/confirm/#{"oops"}")
      assert redirected_to(conn) == "/"
      conn.assigns.flash["error"] =~ "User confirmation link is invalid or it has expired"

      refute Accounts.get_user!(user.id).confirmed_at
    end
  end
end
