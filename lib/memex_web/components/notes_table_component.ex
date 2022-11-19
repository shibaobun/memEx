defmodule MemexWeb.Components.NotesTableComponent do
  @moduledoc """
  A component that displays a list of notes
  """
  use MemexWeb, :live_component
  alias Ecto.UUID
  alias Memex.{Accounts.User, Notes, Notes.Note}
  alias Phoenix.LiveView.{Rendered, Socket}

  @impl true
  @spec update(
          %{
            required(:id) => UUID.t(),
            required(:current_user) => User.t(),
            required(:notes) => [Note.t()],
            optional(any()) => any()
          },
          Socket.t()
        ) :: {:ok, Socket.t()}
  def update(%{id: _id, notes: _notes, current_user: _current_user} = assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:actions, fn -> [] end)
      |> display_notes()

    {:ok, socket}
  end

  defp display_notes(
         %{
           assigns: %{
             notes: notes,
             current_user: current_user,
             actions: actions
           }
         } = socket
       ) do
    columns =
      if actions == [] or current_user |> is_nil() do
        []
      else
        [%{label: nil, key: :actions, sortable: false}]
      end

    columns = [
      %{label: gettext("title"), key: :title},
      %{label: gettext("content"), key: :content},
      %{label: gettext("tags"), key: :tags},
      %{label: gettext("visibility"), key: :visibility}
      | columns
    ]

    rows =
      notes
      |> Enum.map(fn note ->
        note
        |> get_row_data_for_note(%{
          columns: columns,
          current_user: current_user,
          actions: actions
        })
      end)

    socket |> assign(columns: columns, rows: rows)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full">
      <.live_component
        module={MemexWeb.Components.TableComponent}
        id={@id}
        columns={@columns}
        rows={@rows}
      />
    </div>
    """
  end

  @spec get_row_data_for_note(Note.t(), additional_data :: map()) :: map()
  defp get_row_data_for_note(note, %{columns: columns} = additional_data) do
    columns
    |> Map.new(fn %{key: key} ->
      {key, get_value_for_key(key, note, additional_data)}
    end)
  end

  @spec get_value_for_key(atom(), Note.t(), additional_data :: map()) ::
          any() | {any(), Rendered.t()}
  defp get_value_for_key(:title, %{id: id, title: title}, _additional_data) do
    assigns = %{id: id, title: title}

    title_block = ~H"""
    <.link
      navigate={Routes.note_show_path(Endpoint, :show, @id)}
      class="link"
      data-qa={"note-show-#{@id}"}
    >
      <%= @title %>
    </.link>
    """

    {title, title_block}
  end

  defp get_value_for_key(:content, %{content: content}, _additional_data) do
    assigns = %{content: content}

    content_block = ~H"""
    <div class="truncate max-w-sm">
      <%= @content %>
    </div>
    """

    {content, content_block}
  end

  defp get_value_for_key(:tags, %{tags: tags}, _additional_data) do
    tags |> Notes.get_tags_string()
  end

  defp get_value_for_key(:actions, note, %{actions: actions}) do
    assigns = %{actions: actions, note: note}

    ~H"""
    <div class="flex justify-center items-center space-x-4">
      <%= render_slot(@actions, @note) %>
    </div>
    """
  end

  defp get_value_for_key(key, note, _additional_data), do: note |> Map.get(key)
end
