defmodule LokalWeb.Components.TableComponent do
  @moduledoc """
  Livecomponent that presents a resortable table

  It takes the following required assigns:
    - `:columns`: An array of maps containing the following keys
      - `:label`: A gettext'd or otherwise user-facing string label for the
        column. Can be nil
      - `:key`: An atom key used for sorting
      - `:class`: Extra classes to be applied to the column element, if desired.
        Optional
      - `:sortable`: If false, will prevent the user from sorting with it.
        Optional
    - `:values`: An array of maps containing data for each row. Each map is
      string-keyed with the associated column key to the following values:
      - A single element, like string, integer or Phoenix.LiveView.Rendered
        object, like returned from the ~H sigil
      - A tuple, containing a custom value used for sorting, and the displayed
        content.
  """

  use LokalWeb, :live_component
  alias Phoenix.LiveView.Socket
  require Integer

  @impl true
  @spec update(
          %{
            required(:columns) =>
              list(%{
                required(:label) => String.t() | nil,
                required(:key) => atom() | nil,
                optional(:class) => String.t(),
                optional(:row_class) => String.t(),
                optional(:alternate_row_class) => String.t(),
                optional(:sortable) => false
              }),
            required(:rows) =>
              list(%{
                (key :: atom()) => any() | {custom_sort_value :: String.t(), value :: any()}
              }),
            optional(:inital_key) => atom(),
            optional(:initial_sort_mode) => atom(),
            optional(any()) => any()
          },
          Socket.t()
        ) :: {:ok, Socket.t()}
  def update(%{columns: columns, rows: rows} = assigns, socket) do
    initial_key =
      if assigns |> Map.has_key?(:initial_key) do
        assigns.initial_key
      else
        columns |> List.first(%{}) |> Map.get(:key)
      end

    initial_sort_mode =
      if assigns |> Map.has_key?(:initial_sort_mode) do
        assigns.initial_sort_mode
      else
        :asc
      end

    rows = rows |> sort_by_custom_sort_value_or_value(initial_key, initial_sort_mode)

    socket =
      socket
      |> assign(assigns)
      |> assign(
        columns: columns,
        rows: rows,
        last_sort_key: initial_key,
        sort_mode: initial_sort_mode
      )
      |> assign_new(:row_class, fn -> "bg-white" end)
      |> assign_new(:alternate_row_class, fn -> "bg-gray-200" end)

    {:ok, socket}
  end

  @impl true
  def handle_event(
        "sort_by",
        %{"sort-key" => key},
        %{assigns: %{rows: rows, last_sort_key: last_sort_key, sort_mode: sort_mode}} = socket
      ) do
    key = key |> String.to_existing_atom()

    sort_mode =
      case {key, sort_mode} do
        {^last_sort_key, :asc} -> :desc
        {^last_sort_key, :desc} -> :asc
        {_new_sort_key, _last_sort_mode} -> :asc
      end

    rows = rows |> sort_by_custom_sort_value_or_value(key, sort_mode)
    {:noreply, socket |> assign(last_sort_key: key, sort_mode: sort_mode, rows: rows)}
  end

  defp sort_by_custom_sort_value_or_value(rows, key, sort_mode) do
    rows
    |> Enum.sort_by(
      fn row ->
        case row |> Map.get(key) do
          {custom_sort_key, _value} -> custom_sort_key
          value -> value
        end
      end,
      sort_mode
    )
  end
end
