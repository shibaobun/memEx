defmodule Lokal.InvitesTest do
  @moduledoc """
  This module tests the Invites context
  """

  use Lokal.DataCase
  alias Ecto.Changeset
  alias Lokal.{Invites, Invites.Invite}

  @moduletag :invites_test

  @valid_attrs %{
    "name" => "some name",
    "token" => "some token"
  }
  @update_attrs %{
    "name" => "some updated name",
    "token" => "some updated token"
  }
  @invalid_attrs %{
    "name" => nil,
    "token" => nil
  }

  describe "invites" do
    setup do
      current_user = admin_fixture()
      {:ok, invite} = Invites.create_invite(current_user, @valid_attrs)
      [invite: invite, current_user: current_user]
    end

    test "list_invites/0 returns all invites", %{invite: invite, current_user: current_user} do
      assert Invites.list_invites(current_user) == [invite]
    end

    test "get_invite!/1 returns the invite with given id",
         %{invite: invite, current_user: current_user} do
      assert Invites.get_invite!(invite.id, current_user) == invite
    end

    test "create_invite/1 with valid data creates a invite",
         %{current_user: current_user} do
      assert {:ok, %Invite{} = invite} = Invites.create_invite(current_user, @valid_attrs)
      assert invite.name == "some name"
    end

    test "create_invite/1 with invalid data returns error changeset",
         %{current_user: current_user} do
      assert {:error, %Changeset{}} = Invites.create_invite(current_user, @invalid_attrs)
    end

    test "update_invite/2 with valid data updates the invite",
         %{invite: invite, current_user: current_user} do
      assert {:ok, %Invite{} = new_invite} =
               Invites.update_invite(invite, @update_attrs, current_user)

      assert new_invite.name == "some updated name"
      assert new_invite.token == new_invite.token
    end

    test "update_invite/2 with invalid data returns error changeset",
         %{invite: invite, current_user: current_user} do
      assert {:error, %Changeset{}} = Invites.update_invite(invite, @invalid_attrs, current_user)
      assert invite == Invites.get_invite!(invite.id, current_user)
    end

    test "delete_invite/1 deletes the invite", %{invite: invite, current_user: current_user} do
      assert {:ok, %Invite{}} = Invites.delete_invite(invite, current_user)
      assert_raise Ecto.NoResultsError, fn -> Invites.get_invite!(invite.id, current_user) end
    end

    test "change_invite/1 returns a invite changeset", %{invite: invite} do
      assert %Changeset{} = Invites.change_invite(invite)
    end
  end
end
