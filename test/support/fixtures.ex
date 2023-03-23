defmodule Memex.Fixtures do
  @moduledoc """
  This module defines test helpers for creating entities
  """

  import Memex.DataCase
  alias Memex.{Accounts, Accounts.User, Email, Repo}
  alias Memex.{Contexts, Contexts.Context}
  alias Memex.{Notes, Notes.Note}
  alias Memex.{Pipelines, Pipelines.Pipeline, Pipelines.Steps}

  @spec user_fixture() :: User.t()
  @spec user_fixture(attrs :: map()) :: User.t()
  def user_fixture(attrs \\ %{}) do
    attrs
    |> Enum.into(%{
      email: unique_user_email(),
      password: valid_user_password()
    })
    |> Accounts.register_user()
    |> unwrap_ok_tuple()
  end

  @spec admin_fixture() :: User.t()
  @spec admin_fixture(attrs :: map()) :: User.t()
  def admin_fixture(attrs \\ %{}) do
    attrs
    |> Enum.into(%{
      email: unique_user_email(),
      password: valid_user_password()
    })
    |> Accounts.register_user()
    |> unwrap_ok_tuple()
    |> User.role_changeset(:admin)
    |> Repo.update!()
  end

  def extract_user_token(fun) do
    %{args: %{attrs: attrs, email: email_key, user_id: user_id}} = fun.(&"[TOKEN]#{&1}[TOKEN]")

    # convert atoms to string keys
    attrs = attrs |> Map.new(fn {atom_key, value} -> {atom_key |> Atom.to_string(), value} end)

    email =
      email_key
      |> Atom.to_string()
      |> Email.generate_email(Accounts.get_user!(user_id), attrs)

    [_, html_token | _] = email.html_body |> String.split("[TOKEN]")
    [_, text_token | _] = email.text_body |> String.split("[TOKEN]")
    ^text_token = html_token
  end

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      password: valid_user_password()
    })
  end

  @doc """
  Generate a step.
  """
  def step_fixture(attrs \\ %{}, position, pipeline, user) do
    {:ok, step} =
      attrs
      |> Enum.into(%{
        content: random_string(),
        title: random_string()
      })
      |> Steps.create_step(position, pipeline, user)

    step
  end

  @doc """
  Generate a pipeline.
  """
  @spec pipeline_fixture(User.t()) :: Pipeline.t()
  @spec pipeline_fixture(attrs :: map(), User.t()) :: Pipeline.t()
  def pipeline_fixture(attrs \\ %{}, user) do
    {:ok, pipeline} =
      attrs
      |> Enum.into(%{
        description: random_string(),
        tags: [random_slug()],
        slug: random_slug(),
        visibility: :private
      })
      |> Pipelines.create_pipeline(user)

    %{pipeline | tags_string: nil}
  end

  @doc """
  Generate a note.
  """
  @spec note_fixture(User.t()) :: Note.t()
  @spec note_fixture(attrs :: map(), User.t()) :: Note.t()
  def note_fixture(attrs \\ %{}, user) do
    {:ok, note} =
      attrs
      |> Enum.into(%{
        content: random_string(),
        tags: [random_slug()],
        slug: random_slug(),
        visibility: :private
      })
      |> Notes.create_note(user)

    %{note | tags_string: nil}
  end

  @doc """
  Generate a context.
  """
  @spec context_fixture(User.t()) :: Context.t()
  @spec context_fixture(attrs :: map(), User.t()) :: Context.t()
  def context_fixture(attrs \\ %{}, user) do
    {:ok, context} =
      attrs
      |> Enum.into(%{
        content: random_string(),
        tags: [random_slug()],
        slug: random_slug(),
        visibility: :private
      })
      |> Contexts.create_context(user)

    %{context | tags_string: nil}
  end

  defp unwrap_ok_tuple({:ok, value}), do: value
end
