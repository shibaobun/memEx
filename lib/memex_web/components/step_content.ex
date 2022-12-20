defmodule MemexWeb.Components.StepContent do
  @moduledoc """
  Display the content for a step
  """
  use MemexWeb, :component
  alias Memex.Pipelines.Steps.Step
  alias Phoenix.HTML

  attr :step, Step, required: true

  def step_content(assigns) do
    ~H"""
    <div
      id={"show-step-content-#{@step.id}"}
      class="input input-primary h-32 min-h-32 inline-block"
      phx-hook="MaintainAttrs"
      phx-update="ignore"
      readonly
      phx-no-format
    ><p class="inline"><%= add_links_to_content(@step.content) %></p></div>
    """
  end

  defp add_links_to_content(content) do
    Regex.replace(
      ~r/\[\[([\p{L}\p{N}\-]+)\]\]/,
      content,
      fn _whole_match, slug ->
        link =
          HTML.Link.link(
            "[[#{slug}]]",
            to: Routes.context_show_path(Endpoint, :show, slug),
            class: "link inline",
            data: [qa: "step-context-#{slug}"]
          )
          |> HTML.Safe.to_iodata()
          |> IO.iodata_to_binary()

        "</p>#{link}<p class=\"inline\">"
      end
    )
    |> String.replace("\n", "<br>")
    |> HTML.raw()
  end
end
