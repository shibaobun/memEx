defmodule LokalWeb.InviteLiveTest do
  @moduledoc """
  Tests the invite liveview
  """

  use LokalWeb.ConnCase
  import Phoenix.LiveViewTest
  import LokalWeb.Gettext
  alias Lokal.Accounts.Invites

  @moduletag :invite_live_test
  @create_attrs %{"name" => "some name"}
  @update_attrs %{"name" => "some updated name"}
  # @invalid_attrs %{"name" => nil}

  describe "Index" do
    setup [:register_and_log_in_user]

    setup %{current_user: current_user} do
      {:ok, invite} = Invites.create_invite(current_user, @create_attrs)
      %{invite: invite, current_user: current_user}
    end

    test "lists all invites", %{conn: conn, invite: invite} do
      {:ok, _index_live, html} = live(conn, Routes.invite_index_path(conn, :index))

      assert html =~ gettext("Invites")
      assert html =~ invite.name
    end

    test "saves new invite", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, Routes.invite_index_path(conn, :index))

      assert index_live |> element("a", dgettext("actions", "Create Invite")) |> render_click() =~
               gettext("New Invite")

      assert_patch(index_live, Routes.invite_index_path(conn, :new))

      # assert index_live
      #        |> form("#invite-form", invite: @invalid_attrs)
      #        |> render_change() =~ dgettext("errors", "can't be blank")

      {:ok, _live, html} =
        index_live
        |> form("#invite-form", invite: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.invite_index_path(conn, :index))

      assert html =~
               dgettext("prompts", "%{invite_name} created successfully", invite_name: "some name")

      assert html =~ "some name"
    end

    test "updates invite in listing", %{conn: conn, invite: invite} do
      {:ok, index_live, _html} = live(conn, Routes.invite_index_path(conn, :index))

      assert index_live |> element("[data-qa=\"edit-#{invite.id}\"]") |> render_click() =~
               gettext("Edit Invite")

      assert_patch(index_live, Routes.invite_index_path(conn, :edit, invite))

      # assert index_live
      #        |> form("#invite-form", invite: @invalid_attrs)
      #        |> render_change() =~ dgettext("errors", "can't be blank")

      {:ok, _live, html} =
        index_live
        |> form("#invite-form", invite: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, Routes.invite_index_path(conn, :index))

      assert html =~
               dgettext("prompts", "%{invite_name} updated successfully",
                 invite_name: "some updated name"
               )

      assert html =~ "some updated name"
    end

    test "deletes invite in listing", %{conn: conn, invite: invite} do
      {:ok, index_live, _html} = live(conn, Routes.invite_index_path(conn, :index))

      assert index_live |> element("[data-qa=\"delete-#{invite.id}\"]") |> render_click()
      refute has_element?(index_live, "#invite-#{invite.id}")
    end
  end
end
