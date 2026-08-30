defmodule AnimeData.Catalog.Workers.MatchTVDB do
  @moduledoc false

  use Oban.Worker,
    queue: :tvdb_match,
    priority: 3,
    max_attempts: 3,
    tags: ["catalog", "tvdb-match"],
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
  def perform(%Oban.Job{args: %{"mapping_id" => mapping_id}}) do
    AnimeData.Catalog.MatchService.run(mapping_id)
  end
end
