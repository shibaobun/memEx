defmodule MemexWeb.Components.ContextsTableComponent do
  @moduledoc """
  A component that displays a list of contexts
  """
  use MemexWeb, :live_component
  alias Ecto.UUID
  alias Memex.{Accounts.User, Contexts.Context}
  alias Phoenix.LiveView.{Rendered, Socket}

  @impl true
  @spec update(
          %{
            required(:id) => UUID.t(),
            required(:current_user) => User.t(),
            required(:contexts) => [Context.t()],
            optional(any()) => any()
          },
          Socket.t()
        ) :: {:ok, Socket.t()}
  def update(%{id: _id, contexts: _contexts, current_user: _current_user} = assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:actions, fn -> [] end)
      |> display_contexts()

    {:ok, socket}
  end

  defp display_contexts(
         %{
           assigns: %{
             contexts: contexts,
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
      %{label: gettext("slug"), key: :slug},
      %{label: gettext("tags"), key: :tags},
      %{label: gettext("visibility"), key: :visibility}
      | columns
    ]

    rows =
      contexts
      |> Enum.map(fn context ->
        context
        |> get_row_data_for_context(%{
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

  @spec get_row_data_for_context(Context.t(), additional_data :: map()) :: map()
  defp get_row_data_for_context(context, %{columns: columns} = additional_data) do
    columns
    |> Map.new(fn %{key: key} ->
      {key, get_value_for_key(key, context, additional_data)}
    end)
  end

  @spec get_value_for_key(atom(), Context.t(), additional_data :: map()) ::
          any() | {any(), Rendered.t()}
  defp get_value_for_key(:slug, %{slug: slug}, _additional_data) do
    assigns = %{slug: slug}

    slug_block = ~H"""
    <.link
      navigate={Routes.context_show_path(Endpoint, :show, @slug)}
      class="link"
      data-qa={"context-show-#{@slug}"}
    >
      <%= @slug %>
    </.link>
    """

    {slug, slug_block}
  end

  defp get_value_for_key(:tags, %{tags: tags}, _additional_data) do
    tags |> Enum.join(", ")
  end

  defp get_value_for_key(:actions, context, %{actions: actions}) do
    assigns = %{actions: actions, context: context}

    ~H"""
    <div class="flex justify-center items-center space-x-4">
      <%= render_slot(@actions, @context) %>
    </div>
    """
  end

  defp get_value_for_key(key, context, _additional_data), do: context |> Map.get(key)
end
