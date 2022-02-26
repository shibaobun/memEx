defmodule LokalWeb.EmailController do
  @moduledoc """
  A dev controller used to develop on emails
  """

  use LokalWeb, :controller
  alias Lokal.Accounts.User

  plug :put_layout, {LokalWeb.LayoutView, :email}

  @sample_assigns %{
    email: %{subject: "Example subject"},
    url: "https://lokal.bubbletea.dev/sample_url",
    user: %User{email: "sample@email.com"}
  }

  @doc """
  Debug route used to preview emails
  """
  def preview(conn, %{"id" => template}) do
    render(conn, "#{template |> to_string()}.html", @sample_assigns)
  end
end
