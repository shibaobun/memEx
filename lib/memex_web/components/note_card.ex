defmodule MemexWeb.Components.NoteCard do
  @moduledoc """
  Display card for an note
  """

  use MemexWeb, :component

  def note_card(assigns) do
    ~H"""
    <div class="mx-4 my-2 px-8 py-4 flex flex-col justify-center items-center space-y-4
      border border-gray-400 rounded-lg shadow-lg hover:shadow-md
      transition-all duration-300 ease-in-out">
      <h1 class="title text-xl">
        <%= @note.name %>
      </h1>

      <h2 class="title text-md">
        <%= gettext("visibility: %{visibility}", visibility: @note.visibility) %>
      </h2>

      <%= if @inner_block do %>
        <div class="flex space-x-4 justify-center items-center">
          <%= render_slot(@inner_block) %>
        </div>
      <% end %>
    </div>
    """
  end
end
