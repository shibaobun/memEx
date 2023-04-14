defmodule MemexWeb.InviteLiveTest do
  @moduledoc """
  Tests the invite liveview
  """

  use MemexWeb.ConnCase
  import Phoenix.LiveViewTest
  alias Memex.Accounts.Invites

  @moduletag :invite_live_test
  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  describe "Index" do
    setup [:register_and_log_in_user]

    setup %{current_user: current_user} do
      {:ok, invite} = Invites.create_invite(current_user, @create_attrs)
      %{invite: invite, current_user: current_user}
    end

    test "lists all invites", %{conn: conn, invite: invite} do
      {:ok, _index_live, html} = live(conn, ~p"/invites")

      assert html =~ "invites"
      assert html =~ invite.name
    end

    test "saves new invite", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/invites")
      assert index_live |> element("a", "create invite") |> render_click() =~ "new invite"
      assert_patch(index_live, ~p"/invites/new")

      assert index_live
             |> form("#invite-form")
             |> render_change(invite: @invalid_attrs) =~ "can&#39;t be blank"

      {:ok, _live, html} =
        index_live
        |> form("#invite-form")
        |> render_submit(invite: @create_attrs)
        |> follow_redirect(conn, ~p"/invites")

      assert html =~ "some name created successfully"
    end

    test "updates invite in listing", %{conn: conn, invite: invite} do
      {:ok, index_live, _html} = live(conn, ~p"/invites")

      assert index_live
             |> element(~s/a[aria-label="edit invite for #{invite.name}"]/)
             |> render_click() =~ "edit invite"

      assert_patch(index_live, ~p"/invites/#{invite}/edit")

      assert index_live
             |> form("#invite-form")
             |> render_change(invite: @invalid_attrs) =~ "can&#39;t be blank"

      {:ok, _live, html} =
        index_live
        |> form("#invite-form")
        |> render_submit(invite: @update_attrs)
        |> follow_redirect(conn, ~p"/invites")

      assert html =~ "some updated name updated successfully"
    end

    test "deletes invite in listing", %{conn: conn, invite: invite} do
      {:ok, index_live, _html} = live(conn, ~p"/invites")

      assert index_live
             |> element(~s/a[aria-label="delete invite for #{invite.name}"]/)
             |> render_click()

      refute has_element?(index_live, "#invite-#{invite.id}")
    end
  end
end
