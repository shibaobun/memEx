defmodule Memex.Email do
  @moduledoc """
  Emails that can be sent using Swoosh.

  You can find the base email templates at
  `lib/memex_web/templates/layout/email.html.heex` for html emails and
  `lib/memex_web/templates/layout/email.txt.heex` for text emails.
  """

  use Phoenix.Swoosh, view: MemexWeb.EmailView, layout: {MemexWeb.LayoutView, :email}
  import MemexWeb.Gettext
  alias Memex.Accounts.User
  alias MemexWeb.EmailView

  @typedoc """
  Represents an HTML and text body email that can be sent
  """
  @type t() :: Swoosh.Email.t()

  @spec base_email(User.t(), String.t()) :: t()
  defp base_email(%User{email: email}, subject) do
    from = Application.get_env(:memex, Memex.Mailer)[:email_from] || "noreply@localhost"
    name = Application.get_env(:memex, Memex.Mailer)[:email_name]
    new() |> to(email) |> from({name, from}) |> subject(subject)
  end

  @spec generate_email(key :: String.t(), User.t(), attrs :: map()) :: t()
  def generate_email("welcome", user, %{"url" => url}) do
    user
    |> base_email(dgettext("emails", "Confirm your Memex account"))
    |> render_body("confirm_email.html", %{user: user, url: url})
    |> text_body(EmailView.render("confirm_email.txt", %{user: user, url: url}))
  end

  def generate_email("reset_password", user, %{"url" => url}) do
    user
    |> base_email(dgettext("emails", "Reset your Memex password"))
    |> render_body("reset_password.html", %{user: user, url: url})
    |> text_body(EmailView.render("reset_password.txt", %{user: user, url: url}))
  end

  def generate_email("update_email", user, %{"url" => url}) do
    user
    |> base_email(dgettext("emails", "Update your Memex email"))
    |> render_body("update_email.html", %{user: user, url: url})
    |> text_body(EmailView.render("update_email.txt", %{user: user, url: url}))
  end
end
