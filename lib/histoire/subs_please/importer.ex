defmodule Histoire.SubsPlease.Importer do
  @moduledoc false

  require Logger

  alias Histoire.Catalog.Mapping
  alias Histoire.SubsPlease.{DateParser, Download, Parser, Release, ScheduleEntry, Show}

  def show(attributes) do
    Show.upsert(attributes)
  end

  def releases(show_id, releases) when is_list(releases) do
    with {:ok, count} <- import_releases(show_id, releases),
         {:ok, _mapping} <- Mapping.upsert_subsplease(%{subsplease_id: show_id}) do
      {:ok, count}
    end
  end

  def schedule(entries) do
    shows_by_slug = Show.list!() |> Map.new(&{&1.slug, &1})
    observed_at = DateTime.utc_now()
    current_keys = MapSet.new(entries, &{Parser.slug_from_page(&1["page"]), &1["weekday"]})

    with {:ok, count} <-
           Enum.reduce_while(entries, {:ok, 0}, fn entry, {:ok, count} ->
             slug = Parser.slug_from_page(entry["page"])
             show_id = if show = Map.get(shows_by_slug, slug), do: show.id

             with {:ok, scheduled_time} <- DateParser.scheduled_time(entry["time"]),
                  {:ok, _schedule_entry} <-
                    ScheduleEntry.upsert(%{
                      show_id: show_id,
                      slug: slug,
                      title: entry["title"],
                      weekday: entry["weekday"],
                      scheduled_time: scheduled_time,
                      image_url: Parser.absolute_url(entry["image_url"]),
                      aired: entry["aired"] in [true, 1, "1"],
                      observed_at: observed_at,
                      raw: entry
                    }) do
               {:cont, {:ok, count + 1}}
             else
               {:error, error} -> {:halt, {:error, error}}
             end
           end) do
      ScheduleEntry.list!()
      |> Enum.reject(&MapSet.member?(current_keys, {&1.slug, &1.weekday}))
      |> Enum.each(&ScheduleEntry.destroy!/1)

      {:ok, count}
    end
  end

  defp release(show_id, %{kind: kind, name: name, raw: row}) do
    with {:ok, downloads} <- required_list(row, "downloads"),
         {:ok, source_date} <- DateParser.source_date(row["time"]),
         {:ok, released_at} <- DateParser.released_at(row["release_date"]),
         {:ok, release} <-
           Release.upsert(%{
             show_id: show_id,
             kind: kind,
             name: name,
             episode: to_string(row["episode"]),
             source_date: source_date,
             released_at: released_at,
             raw_time: row["time"],
             raw: row
           }),
         :ok <- downloads(release.id, downloads),
         :ok <- maybe_enqueue_nyaa(kind, downloads) do
      {:ok, release}
    end
  end

  defp import_releases(show_id, releases) do
    Enum.reduce_while(releases, {:ok, 0}, fn release, {:ok, count} ->
      case release(show_id, release) do
        {:ok, _release} -> {:cont, {:ok, count + 1}}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
  end

  defp downloads(release_id, downloads) do
    with :ok <-
           Enum.reduce_while(downloads, :ok, fn download, :ok ->
             attributes = %{
               release_id: release_id,
               resolution: to_string(download["res"]),
               torrent_url: download["torrent"],
               magnet_uri: download["magnet"],
               xdcc: download["xdcc"],
               raw: download
             }

             case Download.upsert(attributes) do
               {:ok, _download} -> {:cont, :ok}
               {:error, error} -> {:halt, {:error, error}}
             end
           end) do
      current_resolutions = MapSet.new(downloads, &to_string(&1["res"]))

      Release.get_by_id!(release_id, load: [:downloads]).downloads
      |> Enum.reject(&MapSet.member?(current_resolutions, &1.resolution))
      |> Enum.each(&Download.destroy!/1)

      :ok
    end
  end

  defp maybe_enqueue_nyaa(:batch, downloads) do
    case Enum.max_by(downloads, &resolution/1, fn -> nil end) do
      %{"torrent" => torrent_url} when is_binary(torrent_url) ->
        case Histoire.Nyaa.Jobs.enqueue_torrent(torrent_url) do
          {:ok, _job} ->
            :ok

          {:error, error} ->
            Logger.warning("could not enqueue Nyaa enrichment: #{inspect(error)}")
            :ok
        end

      _download ->
        :ok
    end
  end

  defp maybe_enqueue_nyaa(_kind, _downloads), do: :ok

  defp resolution(%{"res" => value}) do
    case value |> to_string() |> Integer.parse() do
      {resolution, _suffix} -> resolution
      :error -> 0
    end
  end

  defp resolution(_download), do: 0

  defp required_list(map, key) do
    case Map.fetch(map, key) do
      {:ok, value} when is_list(value) -> {:ok, value}
      {:ok, value} -> {:error, {:invalid_collection, key, value}}
      :error -> {:error, {:missing_collection, key}}
    end
  end
end
