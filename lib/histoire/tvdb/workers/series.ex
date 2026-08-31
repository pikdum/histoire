defmodule Histoire.TVDB.Workers.Series do
  @moduledoc false

  use Oban.Worker,
    queue: :tvdb_fetch,
    priority: 3,
    max_attempts: 5,
    tags: ["tvdb", "series"],
    unique: [
      period: :infinity,
      fields: [:worker, :args],
      states: [:available, :scheduled, :executing, :retryable]
    ],
    replace: [
      available: [:priority],
      scheduled: [:priority, :scheduled_at],
      retryable: [:priority, :scheduled_at]
    ]

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"tvdb_id" => tvdb_id}}) do
    case Histoire.TVDB.SyncService.series(tvdb_id) do
      {:ok, _series} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end
end
