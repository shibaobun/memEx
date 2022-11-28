defmodule MemexWeb.HomeLive do
  @moduledoc """
  Liveview for the main home page
  """

  @version Mix.Project.config()[:version]

  use MemexWeb, :live_view
  alias Memex.Accounts
  alias MemexWeb.{Endpoint, FaqLive}

  @impl true
  def mount(_params, _session, socket) do
    admins = Accounts.list_users_by_role(:admin)
    {:ok, socket |> assign(page_title: gettext("home"), admins: admins, version: @version)}
  end
end
