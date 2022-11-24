defmodule Memex.ContextsTest do
  use Memex.DataCase
  import Memex.ContextsFixtures
  alias Memex.{Contexts, Contexts.Context}
  @moduletag :contexts_test
  @invalid_attrs %{content: nil, tag: nil, title: nil, visibility: nil}

  describe "contexts" do
    setup do
      [user: user_fixture()]
    end

    test "list_contexts/1 returns all contexts for a user", %{user: user} do
      context_a = context_fixture(%{title: "a", visibility: :public}, user)
      context_b = context_fixture(%{title: "b", visibility: :unlisted}, user)
      context_c = context_fixture(%{title: "c", visibility: :private}, user)
      assert Contexts.list_contexts(user) == [context_a, context_b, context_c]
    end

    test "list_public_contexts/0 returns public contexts", %{user: user} do
      public_context = context_fixture(%{visibility: :public}, user)
      context_fixture(%{visibility: :unlisted}, user)
      context_fixture(%{visibility: :private}, user)
      assert Contexts.list_public_contexts() == [public_context]
    end

    test "get_context!/1 returns the context with given id", %{user: user} do
      context = context_fixture(%{visibility: :public}, user)
      assert Contexts.get_context!(context.id, user) == context

      context = context_fixture(%{visibility: :unlisted}, user)
      assert Contexts.get_context!(context.id, user) == context

      context = context_fixture(%{visibility: :private}, user)
      assert Contexts.get_context!(context.id, user) == context
    end

    test "get_context!/1 only returns unlisted or public contexts for other users", %{user: user} do
      another_user = user_fixture()
      context = context_fixture(%{visibility: :public}, another_user)
      assert Contexts.get_context!(context.id, user) == context

      context = context_fixture(%{visibility: :unlisted}, another_user)
      assert Contexts.get_context!(context.id, user) == context

      context = context_fixture(%{visibility: :private}, another_user)

      assert_raise Ecto.NoResultsError, fn ->
        Contexts.get_context!(context.id, user)
      end
    end

    test "create_context/1 with valid data creates a context", %{user: user} do
      valid_attrs = %{
        "content" => "some content",
        "tags_string" => "tag1,tag2",
        "title" => "some title",
        "visibility" => :public
      }

      assert {:ok, %Context{} = context} = Contexts.create_context(valid_attrs, user)
      assert context.content == "some content"
      assert context.tags == ["tag1", "tag2"]
      assert context.title == "some title"
      assert context.visibility == :public
    end

    test "create_context/1 with invalid data returns error changeset", %{user: user} do
      assert {:error, %Ecto.Changeset{}} = Contexts.create_context(@invalid_attrs, user)
    end

    test "update_context/2 with valid data updates the context", %{user: user} do
      context = context_fixture(user)

      update_attrs = %{
        "content" => "some updated content",
        "tags_string" => "tag1,tag2",
        "title" => "some updated title",
        "visibility" => :private
      }

      assert {:ok, %Context{} = context} = Contexts.update_context(context, update_attrs, user)
      assert context.content == "some updated content"
      assert context.tags == ["tag1", "tag2"]
      assert context.title == "some updated title"
      assert context.visibility == :private
    end

    test "update_context/2 with invalid data returns error changeset", %{user: user} do
      context = context_fixture(user)
      assert {:error, %Ecto.Changeset{}} = Contexts.update_context(context, @invalid_attrs, user)
      assert context == Contexts.get_context!(context.id, user)
    end

    test "delete_context/1 deletes the context", %{user: user} do
      context = context_fixture(user)
      assert {:ok, %Context{}} = Contexts.delete_context(context, user)
      assert_raise Ecto.NoResultsError, fn -> Contexts.get_context!(context.id, user) end
    end

    test "delete_context/1 deletes the context for an admin user", %{user: user} do
      admin_user = admin_fixture()
      context = context_fixture(user)
      assert {:ok, %Context{}} = Contexts.delete_context(context, admin_user)
      assert_raise Ecto.NoResultsError, fn -> Contexts.get_context!(context.id, user) end
    end

    test "change_context/1 returns a context changeset", %{user: user} do
      context = context_fixture(user)
      assert %Ecto.Changeset{} = Contexts.change_context(context, user)
    end
  end
end
