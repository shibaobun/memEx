defmodule Memex.Pipelines.Steps do
  @moduledoc """
  The context for steps within a pipeline
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias Memex.{Accounts.User, Repo}
  alias Memex.Pipelines.{Pipeline, Steps.Step}

  @doc """
  Returns the list of steps.

  ## Examples

      iex> list_steps(%User{id: 123})
      [%Step{}, ...]

      iex> list_steps("my step", %User{id: 123})
      [%Step{title: "my step"}, ...]

  """
  @spec list_steps(Pipeline.t(), User.t()) :: [Step.t()]
  def list_steps(%{id: pipeline_id}, %{id: user_id}) do
    Repo.all(
      from s in Step,
        where: s.pipeline_id == ^pipeline_id,
        where: s.user_id == ^user_id,
        order_by: s.position
    )
  end

  def list_steps(%{id: pipeline_id, visibility: visibility}, _invalid_user)
      when visibility in [:unlisted, :public] do
    Repo.all(
      from s in Step,
        where: s.pipeline_id == ^pipeline_id,
        order_by: s.position
    )
  end

  @doc """
  Preloads the `:steps` field on a Memex.Pipelines.Pipeline
  """
  @spec preload_steps(Pipeline.t(), User.t()) :: Pipeline.t()
  def preload_steps(pipeline, user) do
    %{pipeline | steps: list_steps(pipeline, user)}
  end

  @doc """
  Gets a single step.

  Raises `Ecto.NoResultsError` if the Step does not exist.

  ## Examples

      iex> get_step!(123, %User{id: 123})
      %Step{}

      iex> get_step!(456, %User{id: 123})
      ** (Ecto.NoResultsError)

  """
  @spec get_step!(Step.id(), User.t()) :: Step.t()
  def get_step!(id, %{id: user_id}) do
    Repo.one!(from n in Step, where: n.id == ^id, where: n.user_id == ^user_id)
  end

  def get_step!(id, _invalid_user) do
    Repo.one!(
      from n in Step,
        where: n.id == ^id,
        where: n.visibility in [:public, :unlisted]
    )
  end

  @doc """
  Creates a step.

  ## Examples

      iex> create_step(%{field: value}, %User{id: 123})
      {:ok, %Step{}}

      iex> create_step(%{field: bad_value}, %User{id: 123})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_step(position :: non_neg_integer(), Pipeline.t(), User.t()) ::
          {:ok, Step.t()} | {:error, Step.changeset()}
  @spec create_step(attrs :: map(), position :: non_neg_integer(), Pipeline.t(), User.t()) ::
          {:ok, Step.t()} | {:error, Step.changeset()}
  def create_step(attrs \\ %{}, position, pipeline, user) do
    Step.create_changeset(attrs, position, pipeline, user) |> Repo.insert()
  end

  @doc """
  Updates a step.

  ## Examples

      iex> update_step(step, %{field: new_value}, %User{id: 123})
      {:ok, %Step{}}

      iex> update_step(step, %{field: bad_value}, %User{id: 123})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_step(Step.t(), attrs :: map(), User.t()) ::
          {:ok, Step.t()} | {:error, Step.changeset()}
  def update_step(%Step{} = step, attrs, user) do
    step
    |> Step.update_changeset(attrs, user)
    |> Repo.update()
  end

  @doc """
  Deletes a step.

  ## Examples

      iex> delete_step(%Step{user_id: 123}, %User{id: 123})
      {:ok, %Step{}}

      iex> delete_step(%Step{}, %User{role: :admin})
      {:ok, %Step{}}

      iex> delete_step(%Step{}, %User{id: 123})
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_step(Step.t(), User.t()) :: {:ok, Step.t()} | {:error, Step.changeset()}
  def delete_step(%Step{user_id: user_id} = step, %{id: user_id}) do
    delete_step(step)
  end

  def delete_step(%Step{} = step, %{role: :admin}) do
    delete_step(step)
  end

  defp delete_step(step) do
    Multi.new()
    |> Multi.delete(:delete_step, step)
    |> Multi.update_all(
      :reorder_steps,
      fn %{delete_step: %{position: position, pipeline_id: pipeline_id}} ->
        from s in Step,
          where: s.pipeline_id == ^pipeline_id,
          where: s.position > ^position,
          update: [set: [position: s.position - 1]]
      end,
      []
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{delete_step: step}} -> {:ok, step}
      {:error, :delete_step, changeset, _changes_so_far} -> {:error, changeset}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking step changes.

  ## Examples

      iex> change_step(step, %User{id: 123})
      %Ecto.Changeset{data: %Step{}}

      iex> change_step(step, %{title: "new title"}, %User{id: 123})
      %Ecto.Changeset{data: %Step{}}

  """
  @spec change_step(Step.t(), User.t()) :: Step.changeset()
  @spec change_step(Step.t(), attrs :: map(), User.t()) :: Step.changeset()
  def change_step(%Step{} = step, attrs \\ %{}, user) do
    step |> Step.update_changeset(attrs, user)
  end

  @spec reorder_step(Step.t(), :up | :down, User.t()) ::
          {:ok, Step.t()} | {:error, Step.changeset()}
  def reorder_step(%Step{position: 0} = step, :up, _user), do: {:error, step}

  def reorder_step(
        %Step{position: position, pipeline_id: pipeline_id, user_id: user_id} = step,
        :up,
        %{id: user_id} = user
      ) do
    Multi.new()
    |> Multi.update_all(
      :reorder_steps,
      from(s in Step,
        where: s.pipeline_id == ^pipeline_id,
        where: s.position == ^position - 1,
        update: [set: [position: ^position]]
      ),
      []
    )
    |> Multi.update(
      :update_step,
      step |> Step.position_changeset(position - 1, user)
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{update_step: step}} -> {:ok, step}
      {:error, :update_step, changeset, _changes_so_far} -> {:error, changeset}
    end
  end

  def reorder_step(
        %Step{pipeline_id: pipeline_id, position: position, user_id: user_id} = step,
        :down,
        %{id: user_id} = user
      ) do
    Multi.new()
    |> Multi.one(
      :step_count,
      from(s in Step, where: s.pipeline_id == ^pipeline_id, distinct: true, select: count(s.id))
    )
    |> Multi.update_all(
      :reorder_steps,
      from(s in Step,
        where: s.pipeline_id == ^pipeline_id,
        where: s.position == ^position + 1,
        update: [set: [position: ^position]]
      ),
      []
    )
    |> Multi.update(:update_step, fn %{step_count: step_count} ->
      new_position = if position >= step_count - 1, do: position, else: position + 1
      step |> Step.position_changeset(new_position, user)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{update_step: step}} -> {:ok, step}
      {:error, :update_step, changeset, _changes_so_far} -> {:error, changeset}
    end
  end
end
