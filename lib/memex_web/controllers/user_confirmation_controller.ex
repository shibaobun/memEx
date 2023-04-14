defmodule MemexWeb.UserConfirmationController do
  use MemexWeb, :controller

  import MemexWeb.Gettext
  alias Memex.Accounts

  def new(conn, _params) do
    render(conn, :new, page_title: gettext("Confirm your account"))
  end

  def create(conn, %{"user" => %{"email" => email}}) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_confirmation_instructions(
        user,
        fn token -> url(MemexWeb.Endpoint, ~p"/users/confirm/#{token}") end
      )
    end

    # Regardless of the outcome, show an impartial success/error message.
    conn
    |> put_flash(
      :info,
      dgettext(
        "prompts",
        "If your email is in our system and it has not been confirmed yet, " <>
          "you will receive an email with instructions shortly."
      )
    )
    |> redirect(to: "/")
  end

  # Do not log in the user after confirmation to avoid a
  # leaked token giving the user access to the account.
  def confirm(conn, %{"token" => token}) do
    case Accounts.confirm_user(token) do
      {:ok, %{email: email}} ->
        conn
        |> put_flash(:info, dgettext("prompts", "%{email} confirmed successfully.", email: email))
        |> redirect(to: "/")

      :error ->
        # If there is a current user and the account was already confirmed,
        # then odds are that the confirmation link was already visited, either
        # by some automation or by the user themselves, so we redirect without
        # a warning message.
        case conn.assigns do
          %{current_user: %{confirmed_at: confirmed_at}} when not is_nil(confirmed_at) ->
            redirect(conn, to: "/")

          %{} ->
            conn
            |> put_flash(
              :error,
              dgettext("errors", "User confirmation link is invalid or it has expired.")
            )
            |> redirect(to: "/")
        end
    end
  end
end
