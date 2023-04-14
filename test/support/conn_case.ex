defmodule MemexWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use MemexWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate
  import Memex.Fixtures
  alias Ecto.Adapters.SQL.Sandbox
  alias Memex.{Accounts, Accounts.User, Repo}

  using do
    quote do
      # credo:disable-for-next-line Credo.Check.Consistency.MultiAliasImportRequireUse
      import Memex.{DataCase, Fixtures}
      import MemexWeb.ConnCase
      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest

      use MemexWeb, :verified_routes

      # The default endpoint for testing
      @endpoint MemexWeb.Endpoint
    end
  end

  setup tags do
    pid = Sandbox.start_owner!(Memex.Repo, shared: not tags[:async])
    on_exit(fn -> Sandbox.stop_owner(pid) end)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc """
  Setup helper that registers and logs in users.

      setup :register_and_log_in_user

  It stores an updated connection and a registered user in the
  test context.
  """
  @spec register_and_log_in_user(%{conn: Plug.Conn.t()}) ::
          %{conn: Plug.Conn.t(), current_user: User.t()}
  def register_and_log_in_user(%{conn: conn}) do
    current_user = user_fixture() |> confirm_user()
    %{conn: log_in_user(conn, current_user), current_user: current_user}
  end

  @spec confirm_user(User.t()) :: User.t()
  def confirm_user(user) do
    {:ok, %{user: user}} = user |> Accounts.confirm_user_multi() |> Repo.transaction()
    user
  end

  @doc """
  Logs the given `user` into the `conn`.

  It returns an updated `conn`.
  """
  def log_in_user(conn, user) do
    token = Memex.Accounts.generate_user_session_token(user)

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:user_token, token)
  end
end
