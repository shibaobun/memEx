defmodule MemexWeb.HomeLive do
  @moduledoc """
  Liveview for the main home page
  """

  use MemexWeb, :live_view
  alias Memex.Accounts

  @version Mix.Project.config()[:version]

  @impl true
  def mount(_params, _session, socket) do
    admins = Accounts.list_users_by_role(:admin)
    {:ok, socket |> assign(page_title: gettext("home"), admins: admins, version: @version)}
  end
end
