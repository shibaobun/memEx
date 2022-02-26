defmodule LokalWeb.Components.Topbar do
  @moduledoc """
  Component that renders a topbar with user functions/links
  """

  use LokalWeb, :component

  alias Lokal.Accounts
  alias LokalWeb.{Endpoint, PageLive}

  def topbar(assigns) do
    assigns =
      %{results: [], title_content: nil, flash: nil, current_user: nil} |> Map.merge(assigns)

    ~H"""
    <nav role="navigation" class="mb-8 px-8 py-4 w-full bg-primary-400">
      <div class="flex flex-col sm:flex-row justify-between items-center">
        <div class="mb-4 sm:mb-0 sm:mr-8 flex flex-row justify-start items-center space-x-2">
          <%= live_redirect("Lokal",
            to: Routes.live_path(Endpoint, PageLive),
            class: "mx-2 my-1 leading-5 text-xl text-white hover:underline"
          ) %>

          <%= if @title_content do %>
            <span class="mx-2 my-1">
              |
            </span>
            <%= @title_content %>
          <% end %>
        </div>

        <hr class="mb-2 sm:hidden hr-light" />

        <ul
          class="flex flex-row flex-wrap justify-center items-center
          text-lg text-white text-ellipsis"
        >
          <%= if @current_user do %>
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
            <%= if @current_user.role == :admin do %>
              <li class="mx-2 my-1">
                <%= live_redirect(gettext("Invites"),
                  to: Routes.invite_index_path(Endpoint, :index),
                  class: "text-primary-600 text-white hover:underline"
                ) %>
              </li>
            <% end %>
            <li class="mx-2 my-1">
              <%= live_redirect(@current_user.email,
                to: Routes.user_settings_path(Endpoint, :edit),
                class: "text-primary-600 text-white hover:underline truncate"
              ) %>
            </li>
            <li class="mx-2 my-1">
              <%= link to: Routes.user_session_path(Endpoint, :delete),
                   method: :delete,
                   data: [confirm: dgettext("prompts", "Are you sure you want to log out?")] do %>
                <i class="fas fa-sign-out-alt"></i>
              <% end %>
            </li>
            <%= if @current_user.role == :admin and function_exported?(Routes, :live_dashboard_path, 2) do %>
              <li class="mx-2 my-1">
                <%= live_redirect to: Routes.live_dashboard_path(Endpoint, :home),
                  class: "text-primary-600 text-white hover:underline" do %>
                  <i class="fas fa-tachometer-alt"></i>
                <% end %>
              </li>
            <% end %>
          <% else %>
            <%= if Accounts.allow_registration?() do %>
              <li class="mx-2 my-1">
                <%= live_redirect(dgettext("actions", "Register"),
                  to: Routes.user_registration_path(Endpoint, :new),
                  class: "text-primary-600 text-white hover:underline truncate"
                ) %>
              </li>
            <% end %>
            <li class="mx-2 my-1">
              <%= live_redirect(dgettext("actions", "Log in"),
                to: Routes.user_session_path(Endpoint, :new),
                class: "text-primary-600 text-white hover:underline truncate"
              ) %>
            </li>
          <% end %>
        </ul>
      </div>
    </nav>
    """
  end
end
