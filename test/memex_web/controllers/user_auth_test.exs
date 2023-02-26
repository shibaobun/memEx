defmodule MemexWeb.UserAuthTest do
  @moduledoc """
  Tests user auth
  """

  use MemexWeb.ConnCase, async: true
  import MemexWeb.Gettext
  alias Memex.Accounts
  alias MemexWeb.UserAuth

  @moduletag :user_auth_test
  @remember_me_cookie "_memex_web_user_remember_me"

  setup %{conn: conn} do
    conn =
      conn
      |> Map.replace!(:secret_key_base, MemexWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    [current_user: user_fixture() |> confirm_user(), conn: conn]
  end

  describe "log_in_user/3" do
    test "stores the user token in the session", %{conn: conn, current_user: current_user} do
      conn = UserAuth.log_in_user(conn, current_user)
      assert token = get_session(conn, :user_token)
      assert get_session(conn, :live_socket_id) == "users_sessions:#{Base.url_encode64(token)}"
      assert redirected_to(conn) == "/"
      assert Accounts.get_user_by_session_token(token)
    end

    test "clears everything previously stored in the session",
         %{conn: conn, current_user: current_user} do
      conn = conn |> put_session(:to_be_removed, "value") |> UserAuth.log_in_user(current_user)
      refute get_session(conn, :to_be_removed)
    end

    test "redirects to the configured path", %{conn: conn, current_user: current_user} do
      conn = conn |> put_session(:user_return_to, "/hello") |> UserAuth.log_in_user(current_user)
      assert redirected_to(conn) == "/hello"
    end

    test "writes a cookie if remember_me is configured", %{conn: conn, current_user: current_user} do
      conn =
        conn |> fetch_cookies() |> UserAuth.log_in_user(current_user, %{"remember_me" => "true"})

      assert get_session(conn, :user_token) == conn.cookies[@remember_me_cookie]

      assert %{value: signed_token, max_age: max_age} = conn.resp_cookies[@remember_me_cookie]
      assert signed_token != get_session(conn, :user_token)
      assert max_age == 5_184_000
    end
  end

  describe "logout_user/1" do
    test "erases session and cookies", %{conn: conn, current_user: current_user} do
      user_token = Accounts.generate_user_session_token(current_user)

      conn =
        conn
        |> put_session(:user_token, user_token)
        |> put_req_cookie(@remember_me_cookie, user_token)
        |> fetch_cookies()
        |> UserAuth.log_out_user()

      refute get_session(conn, :user_token)
      refute conn.cookies[@remember_me_cookie]
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == "/"
      refute Accounts.get_user_by_session_token(user_token)
    end

    test "broadcasts to the given live_socket_id", %{conn: conn} do
      live_socket_id = "users_sessions:abcdef-token"
      MemexWeb.Endpoint.subscribe(live_socket_id)

      conn
      |> put_session(:live_socket_id, live_socket_id)
      |> UserAuth.log_out_user()

      assert_receive %Phoenix.Socket.Broadcast{
        event: "disconnect",
        topic: "users_sessions:abcdef-token"
      }
    end

    test "works even if user is already logged out", %{conn: conn} do
      conn = conn |> fetch_cookies() |> UserAuth.log_out_user()
      refute get_session(conn, :user_token)
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == "/"
    end
  end

  describe "fetch_current_user/2" do
    test "authenticates user from session", %{conn: conn, current_user: current_user} do
      user_token = Accounts.generate_user_session_token(current_user)
      conn = conn |> put_session(:user_token, user_token) |> UserAuth.fetch_current_user([])
      assert conn.assigns.current_user.id == current_user.id
    end

    test "authenticates user from cookies", %{conn: conn, current_user: current_user} do
      logged_in_conn =
        conn |> fetch_cookies() |> UserAuth.log_in_user(current_user, %{"remember_me" => "true"})

      user_token = logged_in_conn.cookies[@remember_me_cookie]
      %{value: signed_token} = logged_in_conn.resp_cookies[@remember_me_cookie]

      conn =
        conn
        |> put_req_cookie(@remember_me_cookie, signed_token)
        |> UserAuth.fetch_current_user([])

      assert get_session(conn, :user_token) == user_token
      assert conn.assigns.current_user.id == current_user.id
    end

    test "does not authenticate if data is missing", %{conn: conn, current_user: current_user} do
      _session_token = Accounts.generate_user_session_token(current_user)
      conn = UserAuth.fetch_current_user(conn, [])
      refute get_session(conn, :user_token)
      refute conn.assigns.current_user
    end
  end

  describe "redirect_if_user_is_authenticated/2" do
    test "redirects if user is authenticated", %{conn: conn, current_user: current_user} do
      conn =
        conn
        |> assign(:current_user, current_user)
        |> UserAuth.redirect_if_user_is_authenticated([])

      assert conn.halted
      assert redirected_to(conn) == "/"
    end

    test "does not redirect if user is not authenticated", %{conn: conn} do
      conn = UserAuth.redirect_if_user_is_authenticated(conn, [])
      refute conn.halted
      refute conn.status
    end
  end

  describe "require_authenticated_user/2" do
    test "redirects if user is not authenticated", %{conn: conn} do
      conn = conn |> fetch_flash() |> UserAuth.require_authenticated_user([])
      assert conn.halted
      assert redirected_to(conn) == Routes.user_session_path(conn, :new)

      assert get_flash(conn, :error) ==
               dgettext("errors", "You must confirm your account and log in to access this page.")
    end

    test "stores the path to redirect to on GET", %{conn: conn} do
      halted_conn =
        %{conn | path_info: ["foo"], query_string: ""}
        |> fetch_flash()
        |> UserAuth.require_authenticated_user([])

      assert halted_conn.halted
      assert get_session(halted_conn, :user_return_to) == "/foo"

      halted_conn =
        %{conn | path_info: ["foo"], query_string: "bar=baz"}
        |> fetch_flash()
        |> UserAuth.require_authenticated_user([])

      assert halted_conn.halted
      assert get_session(halted_conn, :user_return_to) == "/foo?bar=baz"

      halted_conn =
        %{conn | path_info: ["/foo?bar"], method: "POST"}
        |> fetch_flash()
        |> UserAuth.require_authenticated_user([])

      assert halted_conn.halted
      refute get_session(halted_conn, :user_return_to)
    end

    test "does not redirect if user is authenticated", %{conn: conn, current_user: current_user} do
      conn =
        conn |> assign(:current_user, current_user) |> UserAuth.require_authenticated_user([])

      refute conn.halted
      refute conn.status
    end
  end
end
