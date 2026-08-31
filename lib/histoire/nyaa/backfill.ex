defmodule Histoire.Nyaa.Backfill do
  @moduledoc "Enqueues the highest-resolution Nyaa torrent for every known SubsPlease batch."

  alias Histoire.Nyaa.Jobs
  alias Histoire.SubsPlease.{Download, Release}

  require Ash.Query

  @spacing_seconds 2

  def enqueue_batches do
    query =
      Release
      |> Ash.Query.filter(kind == :batch)
      |> Ash.Query.load(downloads: [:nyaa_download_override])

    with {:ok, releases} <- Ash.read(query) do
      releases
      |> Enum.map(&highest_resolution_download/1)
      |> Enum.reject(&is_nil/1)
      |> Enum.with_index()
      |> Enum.reduce_while({:ok, 0}, fn {download, index}, {:ok, count} ->
        case Jobs.enqueue_torrent(Download.nyaa_target(download),
               priority: 0,
               schedule_in: index * @spacing_seconds
             ) do
          {:ok, _job} -> {:cont, {:ok, count + 1}}
          {:error, reason} -> {:halt, {:error, reason}}
        end
      end)
    end
  end

  defp highest_resolution_download(release) do
    Enum.max_by(release.downloads, &resolution/1, fn -> nil end)
  end

  defp resolution(download) do
    case Integer.parse(download.resolution) do
      {resolution, _suffix} -> resolution
      :error -> 0
    end
  end
end
