defmodule MemexWeb.FaqLive do
  @moduledoc """
  Liveview for the faq page
  """

  use MemexWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(page_title: gettext("faq"))}
  end
end
