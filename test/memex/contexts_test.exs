defmodule Memex.ContextsTest do
  use Memex.DataCase

  alias Memex.Contexts

  describe "contexts" do
    alias Memex.Contexts.Context

    import Memex.ContextsFixtures

    @invalid_attrs %{content: nil, tag: nil, title: nil, visibility: nil}

    test "list_contexts/0 returns all contexts" do
      context = context_fixture()
      assert Contexts.list_contexts() == [context]
    end

    test "get_context!/1 returns the context with given id" do
      context = context_fixture()
      assert Contexts.get_context!(context.id) == context
    end

    test "create_context/1 with valid data creates a context" do
      valid_attrs = %{content: "some content", tag: [], title: "some title", visibility: :public}

      assert {:ok, %Context{} = context} = Contexts.create_context(valid_attrs)
      assert context.content == "some content"
      assert context.tag == []
      assert context.title == "some title"
      assert context.visibility == :public
    end

    test "create_context/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Contexts.create_context(@invalid_attrs)
    end

    test "update_context/2 with valid data updates the context" do
      context = context_fixture()

      update_attrs = %{
        content: "some updated content",
        tag: [],
        title: "some updated title",
        visibility: :private
      }

      assert {:ok, %Context{} = context} = Contexts.update_context(context, update_attrs)
      assert context.content == "some updated content"
      assert context.tag == []
      assert context.title == "some updated title"
      assert context.visibility == :private
    end

    test "update_context/2 with invalid data returns error changeset" do
      context = context_fixture()
      assert {:error, %Ecto.Changeset{}} = Contexts.update_context(context, @invalid_attrs)
      assert context == Contexts.get_context!(context.id)
    end

    test "delete_context/1 deletes the context" do
      context = context_fixture()
      assert {:ok, %Context{}} = Contexts.delete_context(context)
      assert_raise Ecto.NoResultsError, fn -> Contexts.get_context!(context.id) end
    end

    test "change_context/1 returns a context changeset" do
      context = context_fixture()
      assert %Ecto.Changeset{} = Contexts.change_context(context)
    end
  end
end
