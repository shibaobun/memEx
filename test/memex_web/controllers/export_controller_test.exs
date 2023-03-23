defmodule MemexWeb.ExportControllerTest do
  @moduledoc """
  Tests the export function
  """

  use MemexWeb.ConnCase
  import Memex.Fixtures

  @moduletag :export_controller_test

  setup [:register_and_log_in_user]

  defp add_data(%{current_user: current_user}) do
    note = note_fixture(current_user)
    context = context_fixture(current_user)
    pipeline = pipeline_fixture(current_user)
    step = step_fixture(0, pipeline, current_user)

    %{
      note: note,
      context: context,
      pipeline: pipeline,
      step: step
    }
  end

  describe "Exports data" do
    setup [:add_data]

    test "in JSON", %{
      conn: conn,
      current_user: current_user,
      note: note,
      context: context,
      pipeline: pipeline,
      step: step
    } do
      conn = get(conn, Routes.export_path(conn, :export, :json))

      ideal_note = %{
        "slug" => note.slug,
        "content" => note.content,
        "tags" => note.tags,
        "visibility" => note.visibility |> to_string(),
        "inserted_at" => note.inserted_at |> NaiveDateTime.to_iso8601(),
        "updated_at" => note.updated_at |> NaiveDateTime.to_iso8601()
      }

      ideal_context = %{
        "slug" => context.slug,
        "content" => context.content,
        "tags" => context.tags,
        "visibility" => context.visibility |> to_string(),
        "inserted_at" => context.inserted_at |> NaiveDateTime.to_iso8601(),
        "updated_at" => context.updated_at |> NaiveDateTime.to_iso8601()
      }

      ideal_pipeline = %{
        "slug" => pipeline.slug,
        "description" => pipeline.description,
        "tags" => pipeline.tags,
        "visibility" => pipeline.visibility |> to_string(),
        "inserted_at" => pipeline.inserted_at |> NaiveDateTime.to_iso8601(),
        "updated_at" => pipeline.updated_at |> NaiveDateTime.to_iso8601(),
        "steps" => [
          %{
            "title" => step.title,
            "content" => step.content,
            "position" => step.position,
            "inserted_at" => step.inserted_at |> NaiveDateTime.to_iso8601(),
            "updated_at" => step.updated_at |> NaiveDateTime.to_iso8601()
          }
        ]
      }

      ideal_user = %{
        "confirmed_at" =>
          current_user.confirmed_at |> Jason.encode!() |> String.replace(~r/\"/, ""),
        "email" => current_user.email,
        "id" => current_user.id,
        "locale" => current_user.locale,
        "role" => to_string(current_user.role),
        "inserted_at" => current_user.inserted_at |> NaiveDateTime.to_iso8601(),
        "updated_at" => current_user.updated_at |> NaiveDateTime.to_iso8601()
      }

      json_resp = conn |> json_response(200)
      assert %{"notes" => [^ideal_note]} = json_resp
      assert %{"contexts" => [^ideal_context]} = json_resp
      assert %{"pipelines" => [^ideal_pipeline]} = json_resp
      assert %{"user" => ^ideal_user} = json_resp
    end
  end
end
