defmodule Memex.PipelinesTest do
  use Memex.DataCase, async: true
  import Memex.Fixtures
  alias Memex.{Pipelines, Pipelines.Pipeline}
  @moduletag :pipelines_test
  @invalid_attrs %{description: nil, tag: nil, slug: nil, visibility: nil}

  describe "pipelines" do
    setup do
      [user: user_fixture()]
    end

    test "list_pipelines/1 returns all pipelines for a user", %{user: user} do
      pipeline_a = pipeline_fixture(%{slug: "a", visibility: :public}, user)
      pipeline_b = pipeline_fixture(%{slug: "b", visibility: :unlisted}, user)
      pipeline_c = pipeline_fixture(%{slug: "c", visibility: :private}, user)
      assert Pipelines.list_pipelines(user) == [pipeline_a, pipeline_b, pipeline_c]
    end

    test "list_pipelines/2 returns relevant pipelines for a user", %{user: user} do
      pipeline_a = pipeline_fixture(%{slug: "dogs", description: "has some treats in it"}, user)
      pipeline_b = pipeline_fixture(%{slug: "cats", tags: ["home"]}, user)

      pipeline_c =
        %{slug: "chickens", description: "bananas stuff", tags: ["life", "decisions"]}
        |> pipeline_fixture(user)

      _shouldnt_return =
        %{slug: "dog", description: "banana treat stuff", visibility: :private}
        |> pipeline_fixture(user_fixture())

      # slug
      assert Pipelines.list_pipelines("dog", user) == [pipeline_a]
      assert Pipelines.list_pipelines("dogs", user) == [pipeline_a]
      assert Pipelines.list_pipelines("cat", user) == [pipeline_b]
      assert Pipelines.list_pipelines("chicken", user) == [pipeline_c]

      # description
      assert Pipelines.list_pipelines("treat", user) == [pipeline_a]
      assert Pipelines.list_pipelines("banana", user) == [pipeline_c]
      assert Pipelines.list_pipelines("stuff", user) == [pipeline_c]

      # tag
      assert Pipelines.list_pipelines("home", user) == [pipeline_b]
      assert Pipelines.list_pipelines("life", user) == [pipeline_c]
      assert Pipelines.list_pipelines("decision", user) == [pipeline_c]
      assert Pipelines.list_pipelines("decisions", user) == [pipeline_c]
    end

    test "list_public_pipelines/0 returns public pipelines", %{user: user} do
      public_pipeline = pipeline_fixture(%{visibility: :public}, user)
      pipeline_fixture(%{visibility: :unlisted}, user)
      pipeline_fixture(%{visibility: :private}, user)
      assert Pipelines.list_public_pipelines() == [public_pipeline]
    end

    test "list_public_pipelines/1 returns relevant pipelines for a user", %{user: user} do
      pipeline_a =
        %{slug: "dogs", description: "has some treats in it", visibility: :public}
        |> pipeline_fixture(user)

      pipeline_b =
        %{slug: "cats", tags: ["home"], visibility: :public}
        |> pipeline_fixture(user)

      pipeline_c =
        %{
          slug: "chickens",
          description: "bananas stuff",
          tags: ["life", "decisions"],
          visibility: :public
        }
        |> pipeline_fixture(user)

      _shouldnt_return =
        %{
          slug: "dog",
          description: "treats bananas stuff",
          tags: ["home", "life", "decisions"],
          visibility: :private
        }
        |> pipeline_fixture(user)

      # slug
      assert Pipelines.list_public_pipelines("dog") == [pipeline_a]
      assert Pipelines.list_public_pipelines("dogs") == [pipeline_a]
      assert Pipelines.list_public_pipelines("cat") == [pipeline_b]
      assert Pipelines.list_public_pipelines("chicken") == [pipeline_c]

      # description
      assert Pipelines.list_public_pipelines("treat") == [pipeline_a]
      assert Pipelines.list_public_pipelines("banana") == [pipeline_c]
      assert Pipelines.list_public_pipelines("stuff") == [pipeline_c]

      # tag
      assert Pipelines.list_public_pipelines("home") == [pipeline_b]
      assert Pipelines.list_public_pipelines("life") == [pipeline_c]
      assert Pipelines.list_public_pipelines("decision") == [pipeline_c]
      assert Pipelines.list_public_pipelines("decisions") == [pipeline_c]
    end

    test "get_pipeline!/1 returns the pipeline with given id", %{user: user} do
      pipeline = pipeline_fixture(%{visibility: :public}, user)
      assert Pipelines.get_pipeline!(pipeline.id, user) == pipeline

      pipeline = pipeline_fixture(%{visibility: :unlisted}, user)
      assert Pipelines.get_pipeline!(pipeline.id, user) == pipeline

      pipeline = pipeline_fixture(%{visibility: :private}, user)
      assert Pipelines.get_pipeline!(pipeline.id, user) == pipeline
    end

    test "get_pipeline!/1 only returns unlisted or public pipelines for other users", %{
      user: user
    } do
      another_user = user_fixture()
      pipeline = pipeline_fixture(%{visibility: :public}, another_user)
      assert Pipelines.get_pipeline!(pipeline.id, user) == pipeline

      pipeline = pipeline_fixture(%{visibility: :unlisted}, another_user)
      assert Pipelines.get_pipeline!(pipeline.id, user) == pipeline

      pipeline = pipeline_fixture(%{visibility: :private}, another_user)

      assert_raise Ecto.NoResultsError, fn ->
        Pipelines.get_pipeline!(pipeline.id, user)
      end
    end

    test "get_pipeline_by_slug/1 returns the pipeline with given id", %{user: user} do
      pipeline = pipeline_fixture(%{slug: "a", visibility: :public}, user)
      assert Pipelines.get_pipeline_by_slug("a", user) == pipeline

      pipeline = pipeline_fixture(%{slug: "b", visibility: :unlisted}, user)
      assert Pipelines.get_pipeline_by_slug("b", user) == pipeline

      pipeline = pipeline_fixture(%{slug: "c", visibility: :private}, user)
      assert Pipelines.get_pipeline_by_slug("c", user) == pipeline
    end

    test "get_pipeline_by_slug/1 only returns unlisted or public pipelines for other users", %{
      user: user
    } do
      another_user = user_fixture()
      pipeline = pipeline_fixture(%{slug: "a", visibility: :public}, another_user)
      assert Pipelines.get_pipeline_by_slug("a", user) == pipeline

      pipeline = pipeline_fixture(%{slug: "b", visibility: :unlisted}, another_user)
      assert Pipelines.get_pipeline_by_slug("b", user) == pipeline

      pipeline_fixture(%{slug: "c", visibility: :private}, another_user)
      assert Pipelines.get_pipeline_by_slug("c", user) |> is_nil()
    end

    test "create_pipeline/1 with valid data creates a pipeline", %{user: user} do
      valid_attrs = %{
        description: "some description",
        tags_string: "tag1,tag2",
        slug: "some-slug",
        visibility: :public
      }

      assert {:ok, %Pipeline{} = pipeline} = Pipelines.create_pipeline(valid_attrs, user)
      assert pipeline.description == "some description"
      assert pipeline.tags == ["tag1", "tag2"]
      assert pipeline.slug == "some-slug"
      assert pipeline.visibility == :public
    end

    test "create_pipeline/1 with invalid data returns error changeset", %{user: user} do
      assert {:error, %Ecto.Changeset{}} = Pipelines.create_pipeline(@invalid_attrs, user)
    end

    test "update_pipeline/2 with valid data updates the pipeline", %{user: user} do
      pipeline = pipeline_fixture(user)

      update_attrs = %{
        description: "some updated description",
        tags_string: "tag1,tag2",
        slug: "some-updated-slug",
        visibility: :private
      }

      assert {:ok, %Pipeline{} = pipeline} =
               Pipelines.update_pipeline(pipeline, update_attrs, user)

      assert pipeline.description == "some updated description"
      assert pipeline.tags == ["tag1", "tag2"]
      assert pipeline.slug == "some-updated-slug"
      assert pipeline.visibility == :private
    end

    test "update_pipeline/2 with invalid data returns error changeset", %{user: user} do
      pipeline = pipeline_fixture(user)

      assert {:error, %Ecto.Changeset{}} =
               Pipelines.update_pipeline(pipeline, @invalid_attrs, user)

      assert pipeline == Pipelines.get_pipeline!(pipeline.id, user)
    end

    test "delete_pipeline/1 deletes the pipeline", %{user: user} do
      pipeline = pipeline_fixture(user)
      assert {:ok, %Pipeline{}} = Pipelines.delete_pipeline(pipeline, user)
      assert_raise Ecto.NoResultsError, fn -> Pipelines.get_pipeline!(pipeline.id, user) end
    end

    test "delete_pipeline/1 deletes the pipeline for an admin user", %{user: user} do
      admin_user = admin_fixture()
      pipeline = pipeline_fixture(user)
      assert {:ok, %Pipeline{}} = Pipelines.delete_pipeline(pipeline, admin_user)
      assert_raise Ecto.NoResultsError, fn -> Pipelines.get_pipeline!(pipeline.id, user) end
    end

    test "change_pipeline/1 returns a pipeline changeset", %{user: user} do
      pipeline = pipeline_fixture(user)
      assert %Ecto.Changeset{} = Pipelines.change_pipeline(pipeline, user)
    end
  end
end
