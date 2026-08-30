defmodule AnimeData.SubsPlease.Workers.Release do
  @moduledoc false

  use Oban.Worker,
    queue: :subsplease,
    priority: 3,
    max_attempts: 5,
    tags: ["subsplease", "releases"],
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

  alias AnimeData.SubsPlease.{Client, Importer}

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"show_id" => show_id}}) do
    with {:ok, releases} <- Client.fetch_releases(show_id),
         {:ok, _count} <- Importer.releases(show_id, releases) do
      :ok
    end
  end
end
