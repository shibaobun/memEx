defmodule Memex.Mailer do
  @moduledoc """
  Mailer adapter for emails

  Since emails are loaded as Oban jobs, the `:attrs` map must be serializable to
  json with Jason, which restricts the use of structs.
  """

  use Swoosh.Mailer, otp_app: :memex
  alias Memex.{Accounts.User, EmailWorker}
  alias Oban.Job

  @doc """
  Deliver instructions to confirm account.
  """
  @spec deliver_confirmation_instructions(User.t(), String.t()) :: Job.t()
  def deliver_confirmation_instructions(%User{id: user_id}, url) do
    %{email: :welcome, user_id: user_id, attrs: %{url: url}}
    |> EmailWorker.new()
    |> Oban.insert!()
  end

  @doc """
  Deliver instructions to reset a user password.
  """
  @spec deliver_reset_password_instructions(User.t(), String.t()) :: Job.t()
  def deliver_reset_password_instructions(%User{id: user_id}, url) do
    %{email: :reset_password, user_id: user_id, attrs: %{url: url}}
    |> EmailWorker.new()
    |> Oban.insert!()
  end

  @doc """
  Deliver instructions to update a user email.
  """
  @spec deliver_update_email_instructions(User.t(), String.t()) :: Job.t()
  def deliver_update_email_instructions(%User{id: user_id}, url) do
    %{email: :update_email, user_id: user_id, attrs: %{url: url}}
    |> EmailWorker.new()
    |> Oban.insert!()
  end
end
