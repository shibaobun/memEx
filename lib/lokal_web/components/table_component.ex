defmodule LokalWeb.Components.TableComponent do
  @moduledoc """
  Livecomponent that presents a resortable table

  It takes the following required assigns:
    - `:columns`: An array of maps containing the following keys
      - `:label`: A gettext'd or otherwise user-facing string label for the
        column. Can be nil
      - `:key`: A string key used for sorting
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

  @impl true
  @spec update(
          %{
            required(:columns) =>
              list(%{
                required(:label) => String.t() | nil,
                required(:key) => String.t() | nil,
                optional(:class) => String.t(),
                optional(:sortable) => false
              }),
            required(:rows) =>
              list(%{
                (key :: String.t()) => any() | {custom_sort_value :: String.t(), value :: any()}
              }),
            optional(any()) => any()
          },
          Socket.t()
        ) :: {:ok, Socket.t()}
  def update(%{columns: columns, rows: rows} = assigns, socket) do
    initial_key = columns |> List.first() |> Map.get(:key)
    rows = rows |> Enum.sort_by(fn row -> row |> Map.get(initial_key) end, :asc)

    socket =
      socket
      |> assign(assigns)
      |> assign(columns: columns, rows: rows, last_sort_key: initial_key, sort_mode: :asc)

    {:ok, socket}
  end

  @impl true
  def handle_event(
        "sort_by",
        %{"sort-key" => key},
        %{assigns: %{rows: rows, last_sort_key: key, sort_mode: sort_mode}} = socket
      ) do
    sort_mode = if sort_mode == :asc, do: :desc, else: :asc
    rows = rows |> sort_by_custom_sort_value_or_value(key, sort_mode)
    {:noreply, socket |> assign(sort_mode: sort_mode, rows: rows)}
  end

  def handle_event(
        "sort_by",
        %{"sort-key" => key},
        %{assigns: %{rows: rows}} = socket
      ) do
    rows = rows |> sort_by_custom_sort_value_or_value(key, :asc)
    {:noreply, socket |> assign(last_sort_key: key, sort_mode: :asc, rows: rows)}
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
