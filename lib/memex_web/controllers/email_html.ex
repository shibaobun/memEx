defmodule MemexWeb.EmailHTML do
  @moduledoc """
  Renders email templates
  """

  use MemexWeb, :html

  embed_templates "email_html/*"
end
