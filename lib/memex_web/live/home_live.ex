defmodule MemexWeb.HomeLive do
  @moduledoc """
  Liveview for the home page
  """

  use MemexWeb, :live_view
  alias Memex.Accounts
  alias MemexWeb.Endpoint

  @version Mix.Project.config()[:version]

  @impl true
  def mount(_params, _session, socket) do
    admins = Accounts.list_users_by_role(:admin)
    socket = socket |> assign(page_title: gettext("Home"), admins: admins, version: @version)
    {:ok, socket}
  end
end
