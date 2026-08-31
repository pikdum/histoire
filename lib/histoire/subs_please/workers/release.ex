defmodule Histoire.SubsPlease.Workers.Release do
  @moduledoc false

  use Oban.Worker,
    queue: :subsplease_fetch,
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

  alias Histoire.Catalog.Mapping
  alias Histoire.SubsPlease.{Client, Importer}

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"show_id" => show_id}}) do
    with {:ok, releases} <- Client.fetch_releases(show_id),
         {:ok, _count} <- Importer.releases(show_id, releases),
         {:ok, mapping} <- Mapping.get_by_subsplease_id(show_id),
         {:ok, _job} <- maybe_enqueue_match(mapping) do
      :ok
    end
  end

  defp maybe_enqueue_match(%{tvdb_id: nil, status: :pending} = mapping) do
    _job = AshOban.run_trigger(mapping, :match_tvdb)
    {:ok, :enqueued}
  end

  defp maybe_enqueue_match(_mapping), do: {:ok, :not_needed}
end
