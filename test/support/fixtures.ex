defmodule Memex.Fixtures do
  @moduledoc """
  This module defines test helpers for creating entities
  """

  alias Memex.{Accounts, Accounts.User, Email, Repo}

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  @spec user_fixture() :: User.t()
  @spec user_fixture(attrs :: map()) :: User.t()
  def user_fixture(attrs \\ %{}) do
    attrs
    |> Enum.into(%{
      "email" => unique_user_email(),
      "password" => valid_user_password()
    })
    |> Accounts.register_user()
    |> unwrap_ok_tuple()
  end

  @spec admin_fixture() :: User.t()
  @spec admin_fixture(attrs :: map()) :: User.t()
  def admin_fixture(attrs \\ %{}) do
    attrs
    |> Enum.into(%{
      "email" => unique_user_email(),
      "password" => valid_user_password()
    })
    |> Accounts.register_user()
    |> unwrap_ok_tuple()
    |> User.role_changeset("admin")
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

  defp unwrap_ok_tuple({:ok, value}), do: value
end
