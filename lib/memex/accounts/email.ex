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
    |> base_email(dgettext("emails", "confirm your memEx account"))
    |> render_body(:confirm_email, %{user: user, url: url})
  end

  def generate_email("reset_password", user, %{"url" => url}) do
    user
    |> base_email(dgettext("emails", "reset your memEx password"))
    |> render_body(:reset_password, %{user: user, url: url})
  end

  def generate_email("update_email", user, %{"url" => url}) do
    user
    |> base_email(dgettext("emails", "update your memEx email"))
    |> render_body(:update_email, %{user: user, url: url})
  end

  defp render_body(email, template, assigns) do
    html_heex = apply(EmailHTML, String.to_existing_atom("#{template}_html"), [assigns])
    html = render_to_string(Layouts, "email_html", "html", email: email, inner_content: html_heex)

    text_heex = apply(EmailHTML, String.to_existing_atom("#{template}_text"), [assigns])
    text = render_to_string(Layouts, "email_text", "text", email: email, inner_content: text_heex)

    email |> html_body(html) |> text_body(text)
  end
end
