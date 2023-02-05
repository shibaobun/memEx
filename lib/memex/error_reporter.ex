defmodule Memex.ErrorReporter do
  @moduledoc """
  Custom logger for telemetry events

  Oban implementation taken from
  https://hexdocs.pm/oban/Oban.html#module-reporting-errors
  """

  require Logger

  def handle_event([:oban, :job, :exception], measure, %{stacktrace: stacktrace} = meta, _config) do
    data =
      get_oban_job_data(meta, measure)
      |> Map.put(:stacktrace, Exception.format_stacktrace(stacktrace))

    Logger.error(meta.reason, data: pretty_encode(data))
  end

  def handle_event([:oban, :job, :start], measure, meta, _config) do
    Logger.info("Started oban job", data: get_oban_job_data(meta, measure) |> pretty_encode())
  end

  def handle_event([:oban, :job, :stop], measure, meta, _config) do
    Logger.info("Finished oban job", data: get_oban_job_data(meta, measure) |> pretty_encode())
  end

  def handle_event([:oban, :job, unhandled_event], measure, meta, _config) do
    data =
      get_oban_job_data(meta, measure)
      |> Map.put(:event, unhandled_event)

    Logger.warning("Unhandled oban job event", data: pretty_encode(data))
  end

  def handle_event(unhandled_event, measure, meta, config) do
    data = %{
      event: unhandled_event,
      meta: meta,
      measurements: measure,
      config: config
    }

    Logger.warning("Unhandled telemetry event", data: pretty_encode(data))
  end

  defp get_oban_job_data(%{job: job}, measure) do
    job
    |> Map.take([:id, :args, :meta, :queue, :worker])
    |> Map.merge(measure)
  end

  defp pretty_encode(data) do
    data
    |> Jason.encode!()
    |> Jason.Formatter.pretty_print()
  end
end
