defmodule Memex.ContextsTest do
  use Memex.DataCase
  import Memex.Fixtures
  alias Memex.{Contexts, Contexts.Context}
  @moduletag :contexts_test
  @invalid_attrs %{content: nil, tag: nil, slug: nil, visibility: nil}

  describe "contexts" do
    setup do
      [user: user_fixture()]
    end

    test "list_contexts/1 returns all contexts for a user", %{user: user} do
      context_a = context_fixture(%{slug: "a", visibility: :public}, user)
      context_b = context_fixture(%{slug: "b", visibility: :unlisted}, user)
      context_c = context_fixture(%{slug: "c", visibility: :private}, user)
      assert Contexts.list_contexts(user) == [context_a, context_b, context_c]
    end

    test "list_contexts/2 returns relevant contexts for a user", %{user: user} do
      context_a = context_fixture(%{slug: "dogs", content: "has some treats in it"}, user)
      context_b = context_fixture(%{slug: "cats", tags: ["home"]}, user)

      context_c =
        %{slug: "chickens", content: "bananas stuff", tags: ["life", "decisions"]}
        |> context_fixture(user)

      _shouldnt_return =
        %{slug: "dog", content: "banana treat stuff", visibility: :private}
        |> context_fixture(user_fixture())

      # slug
      assert Contexts.list_contexts("dog", user) == [context_a]
      assert Contexts.list_contexts("dogs", user) == [context_a]
      assert Contexts.list_contexts("cat", user) == [context_b]
      assert Contexts.list_contexts("chicken", user) == [context_c]

      # content
      assert Contexts.list_contexts("treat", user) == [context_a]
      assert Contexts.list_contexts("banana", user) == [context_c]
      assert Contexts.list_contexts("stuff", user) == [context_c]

      # tag
      assert Contexts.list_contexts("home", user) == [context_b]
      assert Contexts.list_contexts("life", user) == [context_c]
      assert Contexts.list_contexts("decision", user) == [context_c]
      assert Contexts.list_contexts("decisions", user) == [context_c]
    end

    test "list_public_contexts/0 returns public contexts", %{user: user} do
      public_context = context_fixture(%{visibility: :public}, user)
      context_fixture(%{visibility: :unlisted}, user)
      context_fixture(%{visibility: :private}, user)
      assert Contexts.list_public_contexts() == [public_context]
    end

    test "list_public_contexts/1 returns relevant contexts for a user", %{user: user} do
      context_a =
        %{slug: "dogs", content: "has some treats in it", visibility: :public}
        |> context_fixture(user)

      context_b =
        %{slug: "cats", tags: ["home"], visibility: :public}
        |> context_fixture(user)

      context_c =
        %{
          slug: "chickens",
          content: "bananas stuff",
          tags: ["life", "decisions"],
          visibility: :public
        }
        |> context_fixture(user)

      _shouldnt_return =
        %{
          slug: "dog",
          content: "treats bananas stuff",
          tags: ["home", "life", "decisions"],
          visibility: :private
        }
        |> context_fixture(user)

      # slug
      assert Contexts.list_public_contexts("dog") == [context_a]
      assert Contexts.list_public_contexts("dogs") == [context_a]
      assert Contexts.list_public_contexts("cat") == [context_b]
      assert Contexts.list_public_contexts("chicken") == [context_c]

      # content
      assert Contexts.list_public_contexts("treat") == [context_a]
      assert Contexts.list_public_contexts("banana") == [context_c]
      assert Contexts.list_public_contexts("stuff") == [context_c]

      # tag
      assert Contexts.list_public_contexts("home") == [context_b]
      assert Contexts.list_public_contexts("life") == [context_c]
      assert Contexts.list_public_contexts("decision") == [context_c]
      assert Contexts.list_public_contexts("decisions") == [context_c]
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

    test "get_context_by_slug/1 returns the context with given id", %{user: user} do
      context = context_fixture(%{slug: "a", visibility: :public}, user)
      assert Contexts.get_context_by_slug("a", user) == context

      context = context_fixture(%{slug: "b", visibility: :unlisted}, user)
      assert Contexts.get_context_by_slug("b", user) == context

      context = context_fixture(%{slug: "c", visibility: :private}, user)
      assert Contexts.get_context_by_slug("c", user) == context
    end

    test "get_context_by_slug/1 only returns unlisted or public contexts for other users", %{
      user: user
    } do
      another_user = user_fixture()
      context = context_fixture(%{slug: "a", visibility: :public}, another_user)
      assert Contexts.get_context_by_slug("a", user) == context

      context = context_fixture(%{slug: "b", visibility: :unlisted}, another_user)
      assert Contexts.get_context_by_slug("b", user) == context

      context_fixture(%{slug: "c", visibility: :private}, another_user)
      assert Contexts.get_context_by_slug("c", user) |> is_nil()
    end

    test "create_context/1 with valid data creates a context", %{user: user} do
      valid_attrs = %{
        content: "some content",
        tags_string: "tag1,tag2",
        slug: "some-slug",
        visibility: :public
      }

      assert {:ok, %Context{} = context} = Contexts.create_context(valid_attrs, user)
      assert context.content == "some content"
      assert context.tags == ["tag1", "tag2"]
      assert context.slug == "some-slug"
      assert context.visibility == :public
    end

    test "create_context/1 with invalid data returns error changeset", %{user: user} do
      assert {:error, %Ecto.Changeset{}} = Contexts.create_context(@invalid_attrs, user)
    end

    test "update_context/2 with valid data updates the context", %{user: user} do
      context = context_fixture(user)

      update_attrs = %{
        content: "some updated content",
        tags_string: "tag1,tag2",
        slug: "some-updated-slug",
        visibility: :private
      }

      assert {:ok, %Context{} = context} = Contexts.update_context(context, update_attrs, user)
      assert context.content == "some updated content"
      assert context.tags == ["tag1", "tag2"]
      assert context.slug == "some-updated-slug"
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
