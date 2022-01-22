defmodule LokalWeb.Component.Topbar do
  @moduledoc """
  Phoenix.Component for rendering an interactive topbar
  Assign
  """

  use LokalWeb, :component
  alias LokalWeb.{PageLive}

  def topbar(assigns) do
    assigns =
      %{results: [], title_content: nil, current_user: nil, flash: nil}
      |> Map.merge(assigns)

    ~H"""
    <header class="mb-8 px-8 py-4 w-full bg-primary-400">
      <nav role="navigation">
        <div class="flex flex-row justify-between items-center space-x-4">
          <div class="flex flex-row justify-start items-center space-x-2">
            <%= link to: Routes.live_path(LokalWeb.Endpoint, PageLive) do %>
              <h1 class="leading-5 text-xl text-white hover:underline">
                Lokal
              </h1>
            <% end %>
            <%= if @title_content do %>
              <span>|</span>
              <%= render_slot(@title_content) %>
            <% end %>
          </div>
          <ul class="flex flex-row flex-wrap justify-center items-center
            text-lg space-x-4 text-lg text-white">
            <form phx-change="suggest" phx-submit="search">
              <input
                type="text"
                name="q"
                class="input input-primary"
                placeholder="Search"
                list="results"
                autocomplete="off"
              />
              <datalist id="results">
                <%= for {app, _vsn} <- @results do %>
                  <option value={app}>
                    "> <%= app %>
                  </option>
                <% end %>
              </datalist>
            </form>
            <%= if @current_user do %>
              <li>
                <%= @current_user.email %>
              </li>
              <li>
                <%= link("Settings",
                  class: "hover:underline",
                  to: Routes.user_settings_path(LokalWeb.Endpoint, :edit)
                ) %>
              </li>
              <li>
                <%= link("Log out",
                  class: "hover:underline",
                  to: Routes.user_session_path(LokalWeb.Endpoint, :delete),
                  method: :delete
                ) %>
              </li>
              <%= if function_exported?(Routes, :live_dashboard_path, 2) do %>
                <li>
                  <%= link("LiveDashboard",
                    class: "hover:underline",
                    to: Routes.live_dashboard_path(LokalWeb.Endpoint, :home)
                  ) %>
                </li>
              <% end %>
            <% else %>
              <li>
                <%= link("Register",
                  class: "hover:underline",
                  to: Routes.user_registration_path(LokalWeb.Endpoint, :new)
                ) %>
              </li>
              <li>
                <%= link("Log in",
                  class: "hover:underline",
                  to: Routes.user_session_path(LokalWeb.Endpoint, :new)
                ) %>
              </li>
            <% end %>
          </ul>
        </div>
      </nav>
      <%= if @flash && @flash |> Map.has_key?(:info) do %>
        <p class="alert alert-info" role="alert" phx-click="lv:clear-flash" phx-value-key="info">
          <%= live_flash(@flash, :info) %>
        </p>
      <% end %>
      <%= if @flash && @flash |> Map.has_key?(:error) do %>
        <p class="alert alert-danger" role="alert" phx-click="lv:clear-flash" phx-value-key="error">
          <%= live_flash(@flash, :error) %>
        </p>
      <% end %>
    </header>
    """
  end
end
