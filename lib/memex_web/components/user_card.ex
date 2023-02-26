defmodule MemexWeb.Components.UserCard do
  @moduledoc """
  Display card for a user
  """

  use MemexWeb, :component
  alias Memex.Accounts.User

  attr :user, User, required: true
  slot(:inner_block, required: true)

  def user_card(assigns) do
    ~H"""
    <div
      id={"user-#{@user.id}"}
      class="mx-4 my-2 px-8 py-4 flex flex-col justify-center items-center text-center
        border border-gray-400 rounded-lg shadow-lg hover:shadow-md
        transition-all duration-300 ease-in-out"
    >
      <h1 class="px-4 py-2 rounded-lg title text-xl break-all">
        <%= @user.email %>
      </h1>

      <h3 class="px-4 py-2 rounded-lg title text-lg">
        <p>
          <%= if @user.confirmed_at do %>
            <%= gettext(
              "User was confirmed at%{confirmed_datetime}",
              confirmed_datetime: ""
            ) %>
            <.datetime datetime={@user.confirmed_at} />
          <% else %>
            <%= gettext("Email unconfirmed") %>
          <% end %>
        </p>

        <p>
          <%= gettext(
            "User registered on%{registered_datetime}",
            registered_datetime: ""
          ) %>
          <.datetime datetime={@user.inserted_at} />
        </p>
      </h3>

      <div :if={@inner_block} class="px-4 py-2 flex space-x-4 justify-center items-center">
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end
end
