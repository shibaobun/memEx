defmodule Memex.InvitesTest do
  @moduledoc """
  This module tests the Memex.Accounts.Invites context
  """

  use Memex.DataCase
  alias Ecto.Changeset
  alias Memex.Accounts
  alias Memex.Accounts.{Invite, Invites}

  @moduletag :invites_test

  @valid_attrs %{
    name: "some name"
  }
  @invalid_attrs %{
    name: nil,
    token: nil
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

    test "get_use_count/2 returns the correct invite usage",
         %{invite: %{token: token} = invite, current_user: current_user} do
      assert Invites.get_use_count(invite, current_user) |> is_nil()

      assert {:ok, _user} =
               Accounts.register_user(
                 %{email: unique_user_email(), password: valid_user_password()},
                 token
               )

      assert 1 == Invites.get_use_count(invite, current_user)

      assert {:ok, _user} =
               Accounts.register_user(
                 %{email: unique_user_email(), password: valid_user_password()},
                 token
               )

      assert 2 == Invites.get_use_count(invite, current_user)
    end

    test "get_use_counts/2 returns the correct invite usage",
         %{invite: %{id: invite_id, token: token} = invite, current_user: current_user} do
      {:ok, %{id: another_invite_id, token: another_token} = another_invite} =
        Invites.create_invite(current_user, @valid_attrs)

      assert [invite, another_invite] |> Invites.get_use_counts(current_user) == %{}

      assert {:ok, _user} =
               Accounts.register_user(
                 %{email: unique_user_email(), password: valid_user_password()},
                 token
               )

      assert {:ok, _user} =
               Accounts.register_user(
                 %{email: unique_user_email(), password: valid_user_password()},
                 another_token
               )

      use_counts = [invite, another_invite] |> Invites.get_use_counts(current_user)
      assert %{^invite_id => 1} = use_counts
      assert %{^another_invite_id => 1} = use_counts

      assert {:ok, _user} =
               Accounts.register_user(
                 %{email: unique_user_email(), password: valid_user_password()},
                 token
               )

      use_counts = [invite, another_invite] |> Invites.get_use_counts(current_user)
      assert %{^invite_id => 2} = use_counts
      assert %{^another_invite_id => 1} = use_counts
    end

    test "use_invite/1 successfully uses an unlimited invite",
         %{invite: %{token: token} = invite, current_user: current_user} do
      {:ok, invite} = Invites.update_invite(invite, %{uses_left: nil}, current_user)
      assert {:ok, ^invite} = Invites.use_invite(token)
      assert {:ok, ^invite} = Invites.use_invite(token)
      assert {:ok, ^invite} = Invites.use_invite(token)
    end

    test "use_invite/1 successfully decrements an invite",
         %{invite: %{token: token} = invite, current_user: current_user} do
      {:ok, _invite} = Invites.update_invite(invite, %{uses_left: 10}, current_user)
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

    test "create_invite/1 with valid data creates an unlimited invite",
         %{current_user: current_user} do
      assert {:ok, %Invite{} = invite} = Invites.create_invite(current_user, %{name: "some name"})

      assert invite.name == "some name"
    end

    test "create_invite/1 with valid data creates a limited invite",
         %{current_user: current_user} do
      assert {:ok, %Invite{} = invite} =
               Invites.create_invite(current_user, %{name: "some name", uses_left: 10})

      assert invite.name == "some name"
      assert invite.uses_left == 10
    end

    test "create_invite/1 with invalid data returns error changeset",
         %{current_user: current_user} do
      assert {:error, %Changeset{}} = Invites.create_invite(current_user, @invalid_attrs)
    end

    test "update_invite/2 can set an invite to be limited",
         %{invite: invite, current_user: current_user} do
      assert {:ok, %Invite{} = new_invite} =
               Invites.update_invite(
                 invite,
                 %{name: "some updated name", uses_left: 5},
                 current_user
               )

      assert new_invite.name == "some updated name"
      assert new_invite.uses_left == 5
    end

    test "update_invite/2 can set an invite to be unlimited",
         %{invite: invite, current_user: current_user} do
      {:ok, invite} = Invites.update_invite(invite, %{"uses_left" => 5}, current_user)

      assert {:ok, %Invite{} = new_invite} =
               Invites.update_invite(
                 invite,
                 %{name: "some updated name", uses_left: nil},
                 current_user
               )

      assert new_invite.name == "some updated name"
      assert new_invite.uses_left |> is_nil()
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
