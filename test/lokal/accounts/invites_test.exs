defmodule Lokal.InvitesTest do
  @moduledoc """
  This module tests the Lokal.Accounts.Invites context
  """

  use Lokal.DataCase
  alias Ecto.Changeset
  alias Lokal.Accounts.{Invite, Invites}

  @moduletag :invites_test

  @valid_attrs %{
    "name" => "some name",
    "uses_left" => 10
  }
  @update_attrs %{
    "name" => "some updated name",
    "uses_left" => 5
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

    test "valid_invite_token? returns for valid and invalid invite tokens",
         %{invite: %{token: token}} do
      refute Invites.valid_invite_token?(nil)
      refute Invites.valid_invite_token?("")
      assert Invites.valid_invite_token?(token)
    end

    test "valid_invite_token? does not return true for a disabled invite by token",
         %{invite: %{token: token} = invite, current_user: current_user} do
      assert Invites.valid_invite_token?(token)

      {:ok, _invite} = Invites.update_invite(invite, %{uses_left: 1}, current_user)
      {:ok, _invite} = Invites.use_invite(token)

      refute Invites.valid_invite_token?(token)
    end

    test "use_invite/1 successfully uses an unlimited invite",
         %{invite: %{token: token} = invite, current_user: current_user} do
      {:ok, invite} = Invites.update_invite(invite, %{uses_left: nil}, current_user)
      assert {:ok, ^invite} = Invites.use_invite(token)
      assert {:ok, ^invite} = Invites.use_invite(token)
      assert {:ok, ^invite} = Invites.use_invite(token)
    end

    test "use_invite/1 successfully decrements an invite", %{invite: %{token: token}} do
      assert {:ok, %{uses_left: 9}} = Invites.use_invite(token)
      assert {:ok, %{uses_left: 8}} = Invites.use_invite(token)
      assert {:ok, %{uses_left: 7}} = Invites.use_invite(token)
    end

    test "use_invite/1 successfully disactivates an invite",
         %{invite: %{token: token} = invite, current_user: current_user} do
      {:ok, _invite} = Invites.update_invite(invite, %{uses_left: 1}, current_user)
      assert {:ok, %{uses_left: 0, disabled_at: disabled_at}} = Invites.use_invite(token)
      assert not is_nil(disabled_at)
    end

    test "use_invite/1 does not work on disactivated invite",
         %{invite: %{token: token} = invite, current_user: current_user} do
      {:ok, _invite} = Invites.update_invite(invite, %{uses_left: 1}, current_user)
      {:ok, _invite} = Invites.use_invite(token)
      assert {:error, :invalid_token} = Invites.use_invite(token)
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
      assert new_invite.uses_left == 5
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

    test "delete_invite!/1 deletes the invite", %{invite: invite, current_user: current_user} do
      assert %Invite{} = Invites.delete_invite!(invite, current_user)
      assert_raise Ecto.NoResultsError, fn -> Invites.get_invite!(invite.id, current_user) end
    end
  end
end
