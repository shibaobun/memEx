defmodule Lokal.EmailWorker do
  @moduledoc """
  Oban worker that dispatches emails
  """

  use Oban.Worker, queue: :mailers, tags: ["email"]
  alias Lokal.{Accounts, Email, Mailer}

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"email" => email, "user_id" => user_id, "attrs" => attrs}}) do
    Email.generate_email(email, user_id |> Accounts.get_user!(), attrs) |> Mailer.deliver()
  end
end
