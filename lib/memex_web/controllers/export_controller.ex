defmodule MemexWeb.ExportController do
  use MemexWeb, :controller
  alias Memex.{Contexts, Notes, Pipelines, Pipelines.Steps}

  def export(%{assigns: %{current_user: current_user}} = conn, %{"mode" => "json"}) do
    pipelines =
      Pipelines.list_pipelines(current_user)
      |> Enum.map(fn pipeline -> Steps.preload_steps(pipeline, current_user) end)

    json(conn, %{
      user: current_user,
      notes: Notes.list_notes(current_user),
      contexts: Contexts.list_contexts(current_user),
      pipelines: pipelines
    })
  end
end
