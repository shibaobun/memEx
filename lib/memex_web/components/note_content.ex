defmodule MemexWeb.Components.NoteContent do
  @moduledoc """
  Display the content for a note
  """
  use MemexWeb, :component
  alias Memex.Notes.Note
  alias Phoenix.HTML

  attr :note, Note, required: true

  def note_content(assigns) do
    ~H"""
    <div
      id={"show-note-content-#{@note.id}"}
      class="input input-primary h-128 min-h-128 inline-block whitespace-pre-wrap overflow-x-hidden overflow-y-auto"
      phx-hook="MaintainAttrs"
      phx-update="ignore"
      readonly
      phx-no-format
    ><p class="inline"><%= add_links_to_content(@note.content) %></p></div>
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
            to: Routes.note_show_path(Endpoint, :show, slug),
            class: "link inline",
            data: [qa: "note-link-#{slug}"]
          )
          |> HTML.Safe.to_iodata()
          |> IO.iodata_to_binary()

        "</p>#{link}<p class=\"inline\">"
      end
    )
    |> HTML.raw()
  end
end
