defmodule Memex.StepsTest do
  use Memex.DataCase, async: true
  import Memex.Fixtures
  alias Memex.Pipelines.{Steps, Steps.Step}
  @moduletag :steps_test
  @invalid_attrs %{content: nil, title: nil}

  describe "steps" do
    setup do
      user = user_fixture()
      pipeline = pipeline_fixture(user)

      [user: user, pipeline: pipeline]
    end

    test "list_steps/2 returns all steps for a user", %{pipeline: pipeline, user: user} do
      step_a = step_fixture(0, pipeline, user)
      step_b = step_fixture(1, pipeline, user)
      step_c = step_fixture(2, pipeline, user)
      assert Steps.list_steps(pipeline, user) == [step_a, step_b, step_c]
    end

    test "get_step!/2 returns the step with given id", %{pipeline: pipeline, user: user} do
      step = step_fixture(0, pipeline, user)
      assert Steps.get_step!(step.id, user) == step
    end

    test "get_step!/2 only returns unlisted or public steps for other users", %{user: user} do
      another_user = user_fixture()
      another_pipeline = pipeline_fixture(another_user)
      step = step_fixture(0, another_pipeline, another_user)

      assert_raise Ecto.NoResultsError, fn ->
        Steps.get_step!(step.id, user)
      end
    end

    test "create_step/4 with valid data creates a step", %{pipeline: pipeline, user: user} do
      valid_attrs = %{
        content: "some content",
        title: "some title"
      }

      assert {:ok, %Step{} = step} = Steps.create_step(valid_attrs, 0, pipeline, user)
      assert step.content == "some content"
      assert step.title == "some title"
    end

    test "create_step/4 with invalid data returns error changeset",
         %{pipeline: pipeline, user: user} do
      assert {:error, %Ecto.Changeset{}} = Steps.create_step(@invalid_attrs, 0, pipeline, user)
    end

    test "update_step/3 with valid data updates the step", %{pipeline: pipeline, user: user} do
      step = step_fixture(0, pipeline, user)

      update_attrs = %{
        content: "some updated content",
        title: "some updated title"
      }

      assert {:ok, %Step{} = step} = Steps.update_step(step, update_attrs, user)
      assert step.content == "some updated content"
      assert step.title == "some updated title"
    end

    test "update_step/3 with invalid data returns error changeset", %{
      pipeline: pipeline,
      user: user
    } do
      step = step_fixture(0, pipeline, user)
      assert {:error, %Ecto.Changeset{}} = Steps.update_step(step, @invalid_attrs, user)
      assert step == Steps.get_step!(step.id, user)
    end

    test "delete_step/2 deletes the step", %{pipeline: pipeline, user: user} do
      step = step_fixture(0, pipeline, user)
      assert {:ok, %Step{}} = Steps.delete_step(step, user)
      assert_raise Ecto.NoResultsError, fn -> Steps.get_step!(step.id, user) end
    end

    test "delete_step/2 moves past steps up", %{pipeline: pipeline, user: user} do
      first_step = step_fixture(0, pipeline, user)
      second_step = step_fixture(1, pipeline, user)
      assert {:ok, %Step{}} = Steps.delete_step(first_step, user)
      assert %{position: 0} = second_step |> Repo.reload!()
    end

    test "delete_step/2 deletes the step for an admin user", %{pipeline: pipeline, user: user} do
      admin_user = admin_fixture()
      step = step_fixture(0, pipeline, user)
      assert {:ok, %Step{}} = Steps.delete_step(step, admin_user)
      assert_raise Ecto.NoResultsError, fn -> Steps.get_step!(step.id, user) end
    end

    test "change_step/2 returns a step changeset", %{pipeline: pipeline, user: user} do
      step = step_fixture(0, pipeline, user)
      assert %Ecto.Changeset{} = Steps.change_step(step, user)
    end

    test "change_step/1 returns a step changeset", %{pipeline: pipeline, user: user} do
      step = step_fixture(0, pipeline, user)
      assert %Ecto.Changeset{} = Steps.change_step(step, user)
    end

    test "reorder_step/1 reorders steps properly", %{pipeline: pipeline, user: user} do
      [
        %{id: first_step_id} = first_step,
        %{id: second_step_id} = second_step,
        %{id: third_step_id} = third_step
      ] = Enum.map(0..2, fn index -> step_fixture(index, pipeline, user) end)

      Steps.reorder_step(third_step, :up, user)

      assert [
               %{id: ^first_step_id, position: 0},
               %{id: ^third_step_id, position: 1},
               %{id: ^second_step_id, position: 2}
             ] = Steps.list_steps(pipeline, user)

      Steps.reorder_step(first_step, :up, user)

      assert [
               %{id: ^first_step_id, position: 0},
               %{id: ^third_step_id, position: 1},
               %{id: ^second_step_id, position: 2}
             ] = Steps.list_steps(pipeline, user)

      second_step
      |> Repo.reload!()
      |> Steps.reorder_step(:down, user)

      assert [
               %{id: ^first_step_id, position: 0},
               %{id: ^third_step_id, position: 1},
               %{id: ^second_step_id, position: 2}
             ] = Steps.list_steps(pipeline, user)

      Steps.reorder_step(first_step, :down, user)

      assert [
               %{id: ^third_step_id, position: 0},
               %{id: ^first_step_id, position: 1},
               %{id: ^second_step_id, position: 2}
             ] = Steps.list_steps(pipeline, user)
    end
  end
end
