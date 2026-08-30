defmodule AnimeData.SubsPlease.Workers.ShowPage do
  @moduledoc false

  use Oban.Worker,
    queue: :subsplease,
    priority: 3,
    max_attempts: 5,
    tags: ["subsplease", "show-page"],
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

  alias AnimeData.SubsPlease.{Client, Importer, Jobs}

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"slug" => slug}, priority: priority}) do
    with {:ok, attributes} <- Client.fetch_show_page(slug),
         {:ok, show} <- Importer.show(attributes),
         {:ok, _job} <- Jobs.enqueue_releases(show.id, priority: priority) do
      :ok
    end
  end
end
