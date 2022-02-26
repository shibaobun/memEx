defmodule LokalWeb.ErrorHelpers do
  @moduledoc """
  Conveniences for translating and building error messages.
  """

  use Phoenix.HTML
  import Phoenix.LiveView.Helpers
  alias Ecto.Changeset
  alias Phoenix.{HTML.Form, LiveView.Rendered}

  @doc """
  Generates tag for inlined form input errors.
  """
  @spec error_tag(Form.t(), Form.field()) :: Rendered.t()
  @spec error_tag(Form.t(), Form.field(), String.t()) :: Rendered.t()
  def error_tag(form, field, extra_class \\ "") do
    assigns = %{extra_class: extra_class, form: form, field: field}

    ~H"""
    <%= for error <- Keyword.get_values(@form.errors, @field) do %>
      <span class={"invalid-feedback #{@extra_class}"} phx-feedback-for={input_name(@form, @field)}>
        <%= translate_error(error) %>
      </span>
    <% end %>
    """
  end

  @doc """
  Translates an error message using gettext.
  """
  @spec translate_error({String.t(), keyword() | map()}) :: String.t()
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate "is invalid" in the "errors" domain
    #     dgettext("errors", "is invalid")
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # Because the error messages we show in our forms and APIs
    # are defined inside Ecto, we need to translate them dynamically.
    # This requires us to call the Gettext module passing our gettext
    # backend as first argument.
    #
    # Note we use the "errors" domain, which means translations
    # should be written to the errors.po file. The :count option is
    # set by Ecto and indicates we should also apply plural rules.
    if count = opts[:count] do
      Gettext.dngettext(LokalWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(LokalWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Displays all errors from a changeset, or just for a single key
  """
  @spec changeset_errors(Changeset.t()) :: String.t()
  @spec changeset_errors(Changeset.t(), key :: atom()) :: [String.t()] | nil
  def changeset_errors(changeset) do
    changeset
    |> changeset_error_map()
    |> Enum.map_join(". ", fn {key, errors} ->
      "#{key |> humanize()}: #{errors |> Enum.join(", ")}"
    end)
  end

  def changeset_errors(changeset, key) do
    changeset |> changeset_error_map() |> Map.get(key)
  end

  @doc """
  Displays all errors from a changeset in a key value map
  """
  @spec changeset_error_map(Changeset.t()) :: %{atom() => [String.t()]}
  def changeset_error_map(changeset) do
    changeset
    |> Changeset.traverse_errors(fn error -> error |> translate_error() end)
  end
end
