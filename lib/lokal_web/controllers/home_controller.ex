defmodule LokalWeb.HomeController do
  @moduledoc """
  Controller for home page
  """

  use LokalWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
