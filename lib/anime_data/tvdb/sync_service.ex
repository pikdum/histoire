defmodule AnimeData.TVDB.SyncService do
  @moduledoc false

  import Ash.Query

  alias AnimeData.Catalog.Mapping
  alias AnimeData.TVDB.{Client, Importer, Jobs}

  def series(tvdb_id) do
    with {:ok, series} <- Client.fetch_series(tvdb_id),
         {:ok, artworks} <- Client.fetch_artworks(tvdb_id),
         {:ok, record} <- Importer.series(series, artworks) do
      {:ok, record}
    end
  end

  def refresh_all do
    results =
      Mapping
      |> filter(not is_nil(tvdb_id))
      |> Ash.read!()
      |> Enum.with_index()
      |> Enum.map(fn {mapping, index} ->
        Jobs.enqueue_series(mapping.tvdb_id, priority: 3, schedule_in: index * 2)
      end)

    case Enum.find(results, &match?({:error, _}, &1)) do
      nil -> {:ok, %{jobs: length(results)}}
      {:error, error} -> {:error, error}
    end
  end
end
