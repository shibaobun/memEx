defmodule MemexWeb.Components.ContextsTableComponent do
  @moduledoc """
  A component that displays a list of contexts
  """
  use MemexWeb, :live_component
  alias Ecto.UUID
  alias Memex.{Accounts.User, Contexts, Contexts.Context}
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
      %{label: gettext("title"), key: :title},
      %{label: gettext("content"), key: :content},
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
  defp get_value_for_key(:title, %{id: id, title: title}, _additional_data) do
    assigns = %{id: id, title: title}

    title_block = ~H"""
    <.link
      navigate={Routes.context_show_path(Endpoint, :show, @id)}
      class="link"
      data-qa={"context-show-#{@id}"}
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
    tags |> Contexts.get_tags_string()
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
