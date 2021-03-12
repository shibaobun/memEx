defmodule LokalWeb.PageController do
  use LokalWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
