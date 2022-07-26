defmodule Memex.PipelinesTest do
  use Memex.DataCase

  alias Memex.Pipelines

  describe "pipelines" do
    alias Memex.Pipelines.Pipeline

    import Memex.PipelinesFixtures

    @invalid_attrs %{description: nil, title: nil, visibility: nil}

    test "list_pipelines/0 returns all pipelines" do
      pipeline = pipeline_fixture()
      assert Pipelines.list_pipelines() == [pipeline]
    end

    test "get_pipeline!/1 returns the pipeline with given id" do
      pipeline = pipeline_fixture()
      assert Pipelines.get_pipeline!(pipeline.id) == pipeline
    end

    test "create_pipeline/1 with valid data creates a pipeline" do
      valid_attrs = %{description: "some description", title: "some title", visibility: :public}

      assert {:ok, %Pipeline{} = pipeline} = Pipelines.create_pipeline(valid_attrs)
      assert pipeline.description == "some description"
      assert pipeline.title == "some title"
      assert pipeline.visibility == :public
    end

    test "create_pipeline/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Pipelines.create_pipeline(@invalid_attrs)
    end

    test "update_pipeline/2 with valid data updates the pipeline" do
      pipeline = pipeline_fixture()
      update_attrs = %{description: "some updated description", title: "some updated title", visibility: :private}

      assert {:ok, %Pipeline{} = pipeline} = Pipelines.update_pipeline(pipeline, update_attrs)
      assert pipeline.description == "some updated description"
      assert pipeline.title == "some updated title"
      assert pipeline.visibility == :private
    end

    test "update_pipeline/2 with invalid data returns error changeset" do
      pipeline = pipeline_fixture()
      assert {:error, %Ecto.Changeset{}} = Pipelines.update_pipeline(pipeline, @invalid_attrs)
      assert pipeline == Pipelines.get_pipeline!(pipeline.id)
    end

    test "delete_pipeline/1 deletes the pipeline" do
      pipeline = pipeline_fixture()
      assert {:ok, %Pipeline{}} = Pipelines.delete_pipeline(pipeline)
      assert_raise Ecto.NoResultsError, fn -> Pipelines.get_pipeline!(pipeline.id) end
    end

    test "change_pipeline/1 returns a pipeline changeset" do
      pipeline = pipeline_fixture()
      assert %Ecto.Changeset{} = Pipelines.change_pipeline(pipeline)
    end
  end
end
