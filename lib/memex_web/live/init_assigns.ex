defmodule MemexWeb.InitAssigns do
  @moduledoc """
  Ensures common `assigns` are applied to all LiveViews attaching this hook.
  """
  import Phoenix.LiveView
  alias Memex.Accounts

  def on_mount(:default, _params, %{"locale" => locale, "user_token" => user_token}, socket) do
    Gettext.put_locale(locale)

    socket =
      socket
      |> assign_new(:current_user, fn -> Accounts.get_user_by_session_token(user_token) end)

    {:cont, socket}
  end

  def on_mount(:default, _params, _session, socket), do: {:cont, socket}
end
