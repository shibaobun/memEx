defmodule LokalWeb.UserRegistrationController do
  use LokalWeb, :controller
  import LokalWeb.Gettext
  alias Lokal.{Accounts, Invites}
  alias Lokal.Accounts.User
  alias LokalWeb.{Endpoint, PageLive}

  def new(conn, %{"invite" => invite_token}) do
    invite = Invites.get_invite_by_token(invite_token)

    if invite do
      conn |> render_new(invite)
    else
      conn
      |> put_flash(:error, dgettext("errors", "Sorry, this invite was not found or expired"))
      |> redirect(to: Routes.live_path(Endpoint, PageLive))
    end
  end

  def new(conn, _params) do
    if Accounts.allow_registration?() do
      conn |> render_new()
    else
      conn
      |> put_flash(:error, dgettext("errors", "Sorry, public registration is disabled"))
      |> redirect(to: Routes.live_path(Endpoint, PageLive))
    end
  end

  # renders new user registration page
  defp render_new(conn, invite \\ nil) do
    render(conn, "new.html",
      changeset: Accounts.change_user_registration(%User{}),
      invite: invite,
      page_title: gettext("Register")
    )
  end

  def create(conn, %{"user" => %{"invite_token" => invite_token}} = attrs) do
    invite = Invites.get_invite_by_token(invite_token)

    if invite do
      conn |> create_user(attrs, invite)
    else
      conn
      |> put_flash(:error, dgettext("errors", "Sorry, this invite was not found or expired"))
      |> redirect(to: Routes.live_path(Endpoint, PageLive))
    end
  end

  def create(conn, attrs) do
    if Accounts.allow_registration?() do
      conn |> create_user(attrs)
    else
      conn
      |> put_flash(:error, dgettext("errors", "Sorry, public registration is disabled"))
      |> redirect(to: Routes.live_path(Endpoint, PageLive))
    end
  end

  defp create_user(conn, %{"user" => user_params}, invite \\ nil) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        unless invite |> is_nil() do
          invite |> Invites.use_invite!()
        end

        Accounts.deliver_user_confirmation_instructions(
          user,
          &Routes.user_confirmation_url(conn, :confirm, &1)
        )

        conn
        |> put_flash(:info, dgettext("prompts", "Please check your email to verify your account"))
        |> redirect(to: Routes.user_session_path(Endpoint, :new))

      {:error, %Ecto.Changeset{} = changeset} ->
        conn |> render("new.html", changeset: changeset, invite: invite)
    end
  end
end
