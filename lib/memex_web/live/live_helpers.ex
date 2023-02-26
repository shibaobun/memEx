defmodule MemexWeb.LiveHelpers do
  @moduledoc """
  Contains common helper functions for liveviews
  """

  import Phoenix.Component
  alias Phoenix.LiveView.JS

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
  def modal(assigns) do
    ~H"""
    <.link
      id="modal-bg"
      patch={@return_to}
      class="fade-in fixed z-10 left-0 top-0
        w-full h-full overflow-hidden
        p-8 flex flex-col justify-center items-center cursor-auto"
      style="background-color: rgba(0,0,0,0.4);"
      phx-remove={hide_modal()}
    >
      <span class="hidden"></span>
    </.link>

    <div
      id="modal"
      class="fixed z-10 left-0 top-0 pointer-events-none
        w-full h-full overflow-hidden
        p-4 sm:p-8 flex flex-col justify-center items-center"
    >
      <div
        id="modal-content"
        class="fade-in-scale max-w-3xl max-h-3xl relative w-full
          pointer-events-auto overflow-hidden
          px-8 py-4 sm:py-8 flex flex-col justify-start items-stretch
          bg-primary-800 text-primary-400 border-primary-900 border-2 rounded-lg"
      >
        <.link
          patch={@return_to}
          id="close"
          class="absolute top-8 right-10
            text-gray-500 hover:text-gray-800
            transition-all duration-500 ease-in-out"
          phx-remove={hide_modal()}
        >
          <i class="fa-fw fa-lg fas fa-times"></i>
        </.link>

        <div class="overflow-x-hidden overflow-y-auto w-full p-8 flex flex-col space-y-4 justify-start items-stretch">
          <%= render_slot(@inner_block) %>
        </div>
      </div>
    </div>
    """
  end

  defp hide_modal(js \\ %JS{}) do
    js
    |> JS.hide(to: "#modal", transition: "fade-out")
    |> JS.hide(to: "#modal-bg", transition: "fade-out")
    |> JS.hide(to: "#modal-content", transition: "fade-out-scale")
  end

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
  def toggle_button(assigns) do
    assigns = assigns |> assign_new(:id, fn -> assigns.action end)

    ~H"""
    <label for={@id} class="inline-flex relative items-center cursor-pointer">
      <input
        id={@id}
        type="checkbox"
        value={@value}
        checked={@value}
        class="sr-only peer"
        data-qa={@id}
        {
          if assigns |> Map.has_key?(:target),
            do: %{"phx-click": @action, "phx-value-value": @value, "phx-target": @target},
            else: %{"phx-click": @action, "phx-value-value": @value}
        }
      />
      <div class="w-11 h-6 bg-gray-300 rounded-full peer
        peer-focus:ring-4 peer-focus:ring-teal-300 dark:peer-focus:ring-teal-800
        peer-checked:bg-gray-600
        peer-checked:after:translate-x-full peer-checked:after:border-white
        after:content-[''] after:absolute after:top-1 after:left-[2px] after:bg-white after:border-gray-300
        after:border after:rounded-full after:h-5 after:w-5
        after:transition-all after:duration-250 after:ease-in-out
        transition-colors duration-250 ease-in-out">
      </div>
      <span class="ml-3 text-sm font-medium text-gray-900 dark:text-gray-300">
        <%= render_slot(@inner_block) %>
      </span>
    </label>
    """
  end
end
