defmodule Lokal.Mailer do
  @moduledoc """
  Mailer, currently uses Swoosh
  """

  use Swoosh.Mailer, otp_app: :lokal
end
