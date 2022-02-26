defmodule LokalWeb.ViewHelpers do
  @moduledoc """
  Contains common helpers that can be used in liveviews and regular views. These
  are automatically imported into any Phoenix View using `use LokalWeb,
  :view`
  """

  import Phoenix.LiveView.Helpers

  @doc """
  Returns a <time> element that renders the naivedatetime in the user's local
  timezone with Alpine.js
  """
  @spec display_datetime(NaiveDateTime.t() | nil) :: Phoenix.LiveView.Rendered.t()
  def display_datetime(nil), do: ""

  def display_datetime(datetime) do
    assigns = %{
      datetime: datetime |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_iso8601(:extended)
    }

    ~H"""
    <time datetime={@datetime} x-data={"{
        date:
          Intl.DateTimeFormat([], {dateStyle: 'short', timeStyle: 'long'})
            .format(new Date(\"#{@datetime}\"))
      }"} x-text="date">
      <%= @datetime %>
    </time>
    """
  end

  @doc """
  Returns a <date> element that renders the Date in the user's local
  timezone with Alpine.js
  """
  @spec display_date(Date.t() | nil) :: Phoenix.LiveView.Rendered.t()
  def display_date(nil), do: ""

  def display_date(date) do
    assigns = %{date: date |> Date.to_iso8601(:extended)}

    ~H"""
    <time datetime={@date} x-data={"{
        date:
          Intl.DateTimeFormat([], {timeZone: 'Etc/UTC', dateStyle: 'short'}).format(new Date(\"#{@date}\"))
      }"} x-text="date">
      <%= @date %>
    </time>
    """
  end
end
