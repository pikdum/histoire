defmodule AnimeData.TVDB.Workers.Movie do
  @moduledoc false

  use Oban.Worker,
    queue: :tvdb_fetch,
    priority: 3,
    max_attempts: 5,
    tags: ["tvdb", "movie"],
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
    case AnimeData.TVDB.SyncService.movie(tvdb_id) do
      {:ok, _movie} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end
end
