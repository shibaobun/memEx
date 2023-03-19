defmodule MemexWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.
  """
  use Phoenix.Component
  import MemexWeb.{Gettext, ViewHelpers}
  alias Memex.{Accounts, Accounts.Invite, Accounts.User}
  alias Memex.Contexts.Context
  alias Memex.Notes.Note
  alias Memex.Pipelines.Steps.Step
  alias MemexWeb.{Endpoint, HomeLive}
  alias MemexWeb.Router.Helpers, as: Routes
  alias Phoenix.HTML
  alias Phoenix.LiveView.JS

  embed_templates("core_components/*")

  attr :title_content, :string, default: nil
  attr :current_user, User, default: nil

  def topbar(assigns)

  attr :return_to, :string, required: true
  slot(:inner_block)

  @doc """
  Renders a live component inside a modal.

  The rendered modal receives a `:return_to` option to properly update
  the URL when the modal is closed.

  ## Examples

      <.modal return_to={Routes.<%= schema.singular %>_index_path(Endpoint, :index)}>
        <.live_component
          module={<%= inspect context.web_module %>.<%= inspect Module.concat(schema.web_namespace, schema.alias) %>Live.FormComponent}
          id={@<%= schema.singular %>.id || :new}
          title={@page_title}
          action={@live_action}
          return_to={Routes.<%= schema.singular %>_index_path(Endpoint, :index)}
          <%= schema.singular %>: @<%= schema.singular %>
        />
      </.modal>
  """
  def modal(assigns)

  defp hide_modal(js \\ %JS{}) do
    js
    |> JS.hide(to: "#modal", transition: "fade-out")
    |> JS.hide(to: "#modal-bg", transition: "fade-out")
    |> JS.hide(to: "#modal-content", transition: "fade-out-scale")
  end

  attr :action, :string, required: true
  attr :value, :boolean, required: true
  attr :id, :string, default: nil
  slot(:inner_block)

  @doc """
  A toggle button element that can be directed to a liveview or a
  live_component's `handle_event/3`.

  ## Examples

  <.toggle_button action="my_liveview_action" value={@some_value}>
    <span>Toggle me!</span>
  </.toggle_button>
  <.toggle_button action="my_live_component_action" target={@myself} value={@some_value}>
    <span>Whatever you want</span>
  </.toggle_button>
  """
  def toggle_button(assigns)

  attr :user, User, required: true
  slot(:inner_block, required: true)

  def user_card(assigns)

  attr :invite, Invite, required: true
  attr :use_count, :integer, default: nil
  attr :current_user, User, required: true
  slot(:inner_block)
  slot(:code_actions)

  def invite_card(assigns)

  attr :id, :string, required: true
  attr :datetime, :any, required: true, doc: "A `DateTime` struct or nil"

  @doc """
  Phoenix.Component for a <time> element that renders the naivedatetime in the
  user's local timezone
  """
  def datetime(assigns)

  @spec cast_datetime(NaiveDateTime.t() | nil) :: String.t()
  defp cast_datetime(%NaiveDateTime{} = datetime) do
    datetime |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_iso8601(:extended)
  end

  defp cast_datetime(_datetime), do: ""

  attr :id, :string, required: true
  attr :date, :any, required: true, doc: "A `Date` struct or nil"

  @doc """
  Phoenix.Component for a <date> element that renders the Date in the user's
  local timezone
  """
  def date(assigns)

  attr :content, :string, required: true
  attr :filename, :string, default: "qrcode", doc: "filename without .png extension"
  attr :image_class, :string, default: "w-64 h-max"
  attr :width, :integer, default: 384, doc: "width of png to generate"

  @doc """
  Creates a downloadable QR Code element
  """
  def qr_code(assigns)

  attr :note, Note, required: true

  def note_content(assigns) do
    ~H"""
    <div
      id={"show-note-content-#{@note.id}"}
      class="input input-primary h-128 min-h-128 inline-block whitespace-pre-wrap overflow-x-hidden overflow-y-auto"
      phx-hook="MaintainAttrs"
      phx-update="ignore"
      readonly
      phx-no-format
    ><p class="inline"><%= add_links_to_content(@note.content, "note-link") %></p></div>
    """
  end

  attr :context, Context, required: true

  def context_content(assigns) do
    ~H"""
    <div
      id={"show-context-content-#{@context.id}"}
      class="input input-primary h-128 min-h-128 inline-block whitespace-pre-wrap overflow-x-hidden overflow-y-auto"
      phx-hook="MaintainAttrs"
      phx-update="ignore"
      readonly
      phx-no-format
    ><p class="inline"><%= add_links_to_content(@context.content, "context-note") %></p></div>
    """
  end

  attr :step, Step, required: true

  def step_content(assigns) do
    ~H"""
    <div
      id={"show-step-content-#{@step.id}"}
      class="input input-primary h-32 min-h-32 inline-block whitespace-pre-wrap overflow-x-hidden overflow-y-auto"
      phx-hook="MaintainAttrs"
      phx-update="ignore"
      readonly
      phx-no-format
    ><p class="inline"><%= add_links_to_content(@step.content, "step-context") %></p></div>
    """
  end

  defp add_links_to_content(content, data_qa_prefix) do
    Regex.replace(
      ~r/\[\[([\p{L}\p{N}\-]+)\]\]/,
      content,
      fn _whole_match, slug ->
        link =
          HTML.Link.link(
            "[[#{slug}]]",
            to: Routes.note_show_path(Endpoint, :show, slug),
            class: "link inline",
            data: [qa: "#{data_qa_prefix}-#{slug}"]
          )
          |> HTML.Safe.to_iodata()
          |> IO.iodata_to_binary()

        "</p>#{link}<p class=\"inline\">"
      end
    )
    |> HTML.raw()
  end
end
