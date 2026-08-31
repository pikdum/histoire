defmodule Histoire.Nyaa.Workers.EnrichTorrent do
  @moduledoc false

  use Oban.Worker,
    queue: :nyaa_fetch,
    priority: 3,
    max_attempts: 5,
    tags: ["nyaa", "torrent"],
    unique: [
      period: :infinity,
      fields: [:worker, :args],
      states: [:available, :scheduled, :executing, :retryable]
    ]

  alias Histoire.Nyaa.Enrichment

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id}}) do
    case Enrichment.get_or_fetch("https://nyaa.si/view/#{id}") do
      {:ok, _torrent} ->
        :ok

      {:error, {:http_status, status, _path} = reason} when status in [404, 410] ->
        {:cancel, reason}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
