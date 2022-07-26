defmodule Memex.StepsTest do
  use Memex.DataCase

  alias Memex.Steps

  describe "steps" do
    alias Memex.Steps.Step

    import Memex.StepsFixtures

    @invalid_attrs %{description: nil, position: nil, title: nil}

    test "list_steps/0 returns all steps" do
      step = step_fixture()
      assert Steps.list_steps() == [step]
    end

    test "get_step!/1 returns the step with given id" do
      step = step_fixture()
      assert Steps.get_step!(step.id) == step
    end

    test "create_step/1 with valid data creates a step" do
      valid_attrs = %{description: "some description", position: 42, title: "some title"}

      assert {:ok, %Step{} = step} = Steps.create_step(valid_attrs)
      assert step.description == "some description"
      assert step.position == 42
      assert step.title == "some title"
    end

    test "create_step/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Steps.create_step(@invalid_attrs)
    end

    test "update_step/2 with valid data updates the step" do
      step = step_fixture()
      update_attrs = %{description: "some updated description", position: 43, title: "some updated title"}

      assert {:ok, %Step{} = step} = Steps.update_step(step, update_attrs)
      assert step.description == "some updated description"
      assert step.position == 43
      assert step.title == "some updated title"
    end

    test "update_step/2 with invalid data returns error changeset" do
      step = step_fixture()
      assert {:error, %Ecto.Changeset{}} = Steps.update_step(step, @invalid_attrs)
      assert step == Steps.get_step!(step.id)
    end

    test "delete_step/1 deletes the step" do
      step = step_fixture()
      assert {:ok, %Step{}} = Steps.delete_step(step)
      assert_raise Ecto.NoResultsError, fn -> Steps.get_step!(step.id) end
    end

    test "change_step/1 returns a step changeset" do
      step = step_fixture()
      assert %Ecto.Changeset{} = Steps.change_step(step)
    end
  end
end
