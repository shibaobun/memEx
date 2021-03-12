defmodule Lokal.Repo do
  use Ecto.Repo,
    otp_app: :lokal,
    adapter: Ecto.Adapters.Postgres
end
