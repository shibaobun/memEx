defmodule MemexWeb.HomeController do
  @moduledoc """
  Controller for home page
  """

  use MemexWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
