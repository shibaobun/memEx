defmodule MemexWeb.Components.NotesTableComponent do
  @moduledoc """
  A component that displays a list of notes
  """
  use MemexWeb, :live_component
  alias Ecto.UUID
  alias Memex.{Accounts.User, Notes.Note}
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
        [%{label: gettext("actions"), key: :actions, sortable: false}]
      end

    columns = [
      %{label: gettext("slug"), key: :slug},
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
  defp get_value_for_key(:slug, %{slug: slug}, _additional_data) do
    assigns = %{slug: slug}

    slug_block = ~H"""
    <.link navigate={Routes.note_show_path(Endpoint, :show, @slug)} class="link">
      <%= @slug %>
    </.link>
    """

    {slug, slug_block}
  end

  defp get_value_for_key(:tags, %{tags: tags}, _additional_data) do
    assigns = %{tags: tags}

    ~H"""
    <div class="flex flex-wrap justify-center space-x-1">
      <.link :for={tag <- @tags} patch={Routes.note_index_path(Endpoint, :search, tag)} class="link">
        <%= tag %>
      </.link>
    </div>
    """
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
