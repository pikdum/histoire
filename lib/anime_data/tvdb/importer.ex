defmodule AnimeData.TVDB.Importer do
  @moduledoc false

  alias AnimeData.TVDB.{Artwork, Season, Series}

  def series(series, artworks) when is_map(series) and is_list(artworks) do
    fetched_at = DateTime.utc_now()
    status = series["status"] || %{}

    with {:ok, record} <-
           Series.upsert(%{
             id: series["id"],
             name: series["name"],
             slug: series["slug"],
             overview: series["overview"],
             image_url: series["image"],
             first_aired: date(series["firstAired"]),
             last_aired: date(series["lastAired"]),
             next_aired: date(series["nextAired"]),
             year: to_optional_string(series["year"]),
             status_id: status["id"],
             status_name: status["name"],
             original_country: series["originalCountry"],
             original_language: series["originalLanguage"],
             average_runtime: series["averageRuntime"],
             score: series["score"],
             raw: series,
             fetched_at: fetched_at
           }),
         :ok <- replace_seasons(record.id, series["seasons"] || []),
         :ok <- replace_artworks(record.id, artworks) do
      {:ok, record}
    end
  end

  defp replace_seasons(series_id, rows) do
    with :ok <-
           upsert_all(rows, fn row ->
             type = row["type"] || %{}

             Season.upsert(%{
               id: row["id"],
               series_id: series_id,
               number: row["number"],
               name: row["name"],
               image_url: row["image"],
               overview: row["overview"],
               type_id: type["id"],
               type_name: type["name"],
               raw: row
             })
           end) do
      remove_missing(Season.list!(), series_id, rows)
      :ok
    end
  end

  defp replace_artworks(series_id, rows) do
    with :ok <-
           upsert_all(rows, fn row ->
             Artwork.upsert(%{
               id: row["id"],
               series_id: series_id,
               artwork_type: row["type"],
               language: row["language"],
               image_url: row["image"],
               thumbnail_url: row["thumbnail"],
               includes_text: row["includesText"],
               score: row["score"],
               width: row["width"],
               height: row["height"],
               raw: row
             })
           end) do
      remove_missing(Artwork.list!(), series_id, rows)
      :ok
    end
  end

  defp upsert_all(rows, function) do
    Enum.reduce_while(rows, :ok, fn row, :ok ->
      case function.(row) do
        {:ok, _record} -> {:cont, :ok}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
  end

  defp remove_missing(records, series_id, rows) do
    current_ids = MapSet.new(rows, & &1["id"])

    records
    |> Enum.filter(&(&1.series_id == series_id))
    |> Enum.reject(&MapSet.member?(current_ids, &1.id))
    |> Enum.each(&Ash.destroy!/1)
  end

  defp date(nil), do: nil
  defp date(""), do: nil

  defp date(value) when is_binary(value) do
    case Date.from_iso8601(value) do
      {:ok, date} -> date
      {:error, _reason} -> nil
    end
  end

  defp to_optional_string(nil), do: nil
  defp to_optional_string(value), do: to_string(value)
end
