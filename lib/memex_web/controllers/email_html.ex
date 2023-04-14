defmodule MemexWeb.EmailHTML do
  @moduledoc """
  Renders email templates
  """

  use MemexWeb, :html

  embed_templates "email_html/*.html", suffix: "_html"
  embed_templates "email_html/*.txt", suffix: "_text"
end
