defmodule MemexWeb.LiveHelpers do
  @moduledoc """
  Contains resuable methods for all liveviews
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
      patch={@return_to}
      id="modal-bg"
      class="fade-in fixed z-10 left-0 top-0
         w-screen h-screen overflow-hidden
         p-8 flex flex-col justify-center items-center cursor-auto"
      style="background-color: rgba(0,0,0,0.4);"
      phx-remove={hide_modal()}
    >
      <span class="hidden"></span>
    </.link>

    <div
      id="modal"
      class="fixed z-10 left-0 top-0 pointer-events-none
        w-screen h-screen overflow-hidden
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

        <div class="overflow-x-hidden overflow-y-visible p-8 flex flex-col space-y-4 justify-start items-stretch">
          <%= render_slot(@inner_block) %>
        </div>
      </div>
    </div>
    """
  end

  def hide_modal(js \\ %JS{}) do
    js
    |> JS.hide(to: "#modal", transition: "fade-out")
    |> JS.hide(to: "#modal-bg", transition: "fade-out")
    |> JS.hide(to: "#modal-content", transition: "fade-out-scale")
  end
end
