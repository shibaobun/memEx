defmodule Memex.Email do
  @moduledoc """
  Emails that can be sent using Swoosh.

  You can find the base email templates at
  `lib/memex_web/components/layouts/email_html.html.heex` for html emails and
  `lib/memex_web/components/layouts/email_text.txt.eex` for text emails.
  """

  import Swoosh.Email
  import MemexWeb.Gettext
  import Phoenix.Template
  alias Memex.Accounts.User
  alias MemexWeb.{EmailHTML, Layouts}

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
    |> html_email(:confirm_email_html, %{user: user, url: url})
    |> text_email(:confirm_email_text, %{user: user, url: url})
  end

  def generate_email("reset_password", user, %{"url" => url}) do
    user
    |> base_email(dgettext("emails", "Reset your Memex password"))
    |> html_email(:reset_password_html, %{user: user, url: url})
    |> text_email(:reset_password_text, %{user: user, url: url})
  end

  def generate_email("update_email", user, %{"url" => url}) do
    user
    |> base_email(dgettext("emails", "Update your Memex email"))
    |> html_email(:update_email_html, %{user: user, url: url})
    |> text_email(:update_email_text, %{user: user, url: url})
  end

  defp html_email(email, atom, assigns) do
    heex = apply(EmailHTML, atom, [assigns])
    html = render_to_string(Layouts, "email_html", "html", email: email, inner_content: heex)
    email |> html_body(html)
  end

  defp text_email(email, atom, assigns) do
    heex = apply(EmailHTML, atom, [assigns])
    text = render_to_string(Layouts, "email_text", "text", email: email, inner_content: heex)
    email |> text_body(text)
  end
end
