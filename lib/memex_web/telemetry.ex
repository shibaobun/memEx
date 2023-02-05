defmodule MemexWeb.Telemetry do
  @moduledoc """
  Collects telemetry
  """

  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      # Telemetry poller will execute the given period measurements
      # every 10_000ms. Learn more here: https://hexdocs.pm/telemetry_metrics
      {:telemetry_poller, measurements: periodic_measurements(), period: 10_000}
      # Add reporters as children of your supervision tree.
      # {Telemetry.Metrics.ConsoleReporter, metrics: metrics()}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def metrics do
    [
      # Phoenix Metrics
      summary("phoenix.endpoint.stop.duration",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.router_dispatch.stop.duration",
        tags: [:route],
        unit: {:native, :millisecond}
      ),

      # Database Metrics
      summary("memex.repo.query.total_time",
        unit: {:native, :millisecond},
        description: "The sum of the other measurements"
      ),
      summary("memex.repo.query.decode_time",
        unit: {:native, :millisecond},
        description: "The time spent decoding the data received from the database"
      ),
      summary("memex.repo.query.query_time",
        unit: {:native, :millisecond},
        description: "The time spent executing the query"
      ),
      summary("memex.repo.query.queue_time",
        unit: {:native, :millisecond},
        description: "The time spent waiting for a database connection"
      ),
      summary("memex.repo.query.idle_time",
        unit: {:native, :millisecond},
        description:
          "The time the connection spent waiting before being checked out for the query"
      ),

      # Oban Metrics
      counter("oban.job.exception",
        tags: [:queue, :worker],
        event_name: [:oban, :job, :exception],
        measurement: :duration,
        description: "Number of oban jobs that raised an exception"
      ),
      counter("oban.job.start",
        tags: [:queue, :worker],
        event_name: [:oban, :job, :start],
        measurement: :system_time,
        description: "Number of oban jobs started"
      ),
      summary("oban.job.stop.duration",
        tags: [:queue, :worker],
        unit: {:native, :millisecond},
        description: "Length of time spent processing the oban job"
      ),
      summary("oban.job.stop.queue_time",
        tags: [:queue, :worker],
        unit: {:native, :millisecond},
        description: "Time the oban job spent waiting in milliseconds"
      ),

      # VM Metrics
      summary("vm.memory.total", unit: {:byte, :kilobyte}),
      summary("vm.total_run_queue_lengths.total"),
      summary("vm.total_run_queue_lengths.cpu"),
      summary("vm.total_run_queue_lengths.io")
    ]
  end

  defp periodic_measurements do
    [
      # A module, function and arguments to be invoked periodically.
      # This function must call :telemetry.execute/3 and a metric must be added above.
      # {MemexWeb, :count_users, []}
    ]
  end
end
