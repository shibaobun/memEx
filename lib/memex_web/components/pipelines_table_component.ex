defmodule MemexWeb.Components.PipelinesTableComponent do
  @moduledoc """
  A component that displays a list of pipelines
  """
  use MemexWeb, :live_component
  alias Ecto.UUID
  alias Memex.{Accounts.User, Pipelines.Pipeline}
  alias Phoenix.LiveView.{Rendered, Socket}

  @impl true
  @spec update(
          %{
            required(:id) => UUID.t(),
            required(:current_user) => User.t(),
            required(:pipelines) => [Pipeline.t()],
            optional(any()) => any()
          },
          Socket.t()
        ) :: {:ok, Socket.t()}
  def update(%{id: _id, pipelines: _pipelines, current_user: _current_user} = assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:actions, fn -> [] end)
      |> display_pipelines()

    {:ok, socket}
  end

  defp display_pipelines(
         %{
           assigns: %{
             pipelines: pipelines,
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
      %{label: gettext("description"), key: :description},
      %{label: gettext("tags"), key: :tags},
      %{label: gettext("visibility"), key: :visibility}
      | columns
    ]

    rows =
      pipelines
      |> Enum.map(fn pipeline ->
        pipeline
        |> get_row_data_for_pipeline(%{
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

  @spec get_row_data_for_pipeline(Pipeline.t(), additional_data :: map()) :: map()
  defp get_row_data_for_pipeline(pipeline, %{columns: columns} = additional_data) do
    columns
    |> Map.new(fn %{key: key} ->
      {key, get_value_for_key(key, pipeline, additional_data)}
    end)
  end

  @spec get_value_for_key(atom(), Pipeline.t(), additional_data :: map()) ::
          any() | {any(), Rendered.t()}
  defp get_value_for_key(:slug, %{slug: slug}, _additional_data) do
    assigns = %{slug: slug}

    slug_block = ~H"""
    <.link navigate={~p"/pipeline/#{@slug}"} class="link">
      <%= @slug %>
    </.link>
    """

    {slug, slug_block}
  end

  defp get_value_for_key(:description, %{description: description}, _additional_data) do
    assigns = %{description: description}

    description_block = ~H"""
    <div class="truncate max-w-sm">
      <%= @description %>
    </div>
    """

    {description, description_block}
  end

  defp get_value_for_key(:tags, %{tags: tags}, _additional_data) do
    assigns = %{tags: tags}

    ~H"""
    <div class="flex flex-wrap justify-center space-x-1">
      <.link :for={tag <- @tags} patch={~p"/pipelines/#{tag}"} class="link">
        <%= tag %>
      </.link>
    </div>
    """
  end

  defp get_value_for_key(:actions, pipeline, %{actions: actions}) do
    assigns = %{actions: actions, pipeline: pipeline}

    ~H"""
    <div class="flex justify-center items-center space-x-4">
      <%= render_slot(@actions, @pipeline) %>
    </div>
    """
  end

  defp get_value_for_key(key, pipeline, _additional_data), do: pipeline |> Map.get(key)
end
