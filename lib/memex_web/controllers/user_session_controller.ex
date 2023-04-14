defmodule MemexWeb.UserSessionController do
  use MemexWeb, :controller

  alias Memex.Accounts
  alias MemexWeb.UserAuth

  def new(conn, _params) do
    render(conn, :new, error_message: nil, page_title: gettext("log in"))
  end

  def create(conn, %{"user" => user_params}) do
    %{"email" => email, "password" => password} = user_params

    if user = Accounts.get_user_by_email_and_password(email, password) do
      UserAuth.log_in_user(conn, user, user_params)
    else
      render(conn, :new, error_message: dgettext("errors", "invalid email or password"))
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, dgettext("prompts", "logged out successfully."))
    |> UserAuth.log_out_user()
  end
end
