defmodule Histoire.Catalog.ReadModel do
  @moduledoc "Builds the small, source-neutral read model consumed by Histoire clients."

  alias Histoire.SubsPlease.{ScheduleEntry, Show}
  alias Histoire.Torrents.Magnet

  import Ash.Expr

  require Ash.Query

  @catalog_load [mapping: [tvdb_series: [:fanart_url, :poster_url, :seasons], tvdb_movie: []]]
  @video_extensions ~w(.3gp .avi .flv .m2ts .m4v .mkv .mov .mp4 .mpeg .mpg .mts .ts .vob .webm .wmv)

  def list_shows(search \\ nil) do
    query =
      Show
      |> Ash.Query.sort(:name)
      |> Ash.Query.load([:latest_episode | @catalog_load])
      |> maybe_search(normalize_search(search))

    with {:ok, shows} <- Ash.read(query) do
      {:ok, Enum.map(shows, &show_summary/1)}
    end
  end

  def get_show(id) when is_integer(id) and id > 0 do
    load = [:latest_episode, releases: [:downloads]] ++ @catalog_load

    with {:ok, show} <- Show.get_by_id(id, load: load) do
      {:ok, show_detail(show)}
    end
  end

  def get_show(_id), do: {:error, :invalid_id}

  def schedule do
    load = [show: [:latest_episode | @catalog_load]]

    with {:ok, entries} <- ScheduleEntry.list(query: [load: load]) do
      {:ok,
       entries
       |> Enum.sort_by(&schedule_sort_key/1)
       |> Enum.map(&schedule_entry/1)}
    end
  end

  def download_files(torrent) do
    files =
      torrent.files
      |> Enum.filter(&video_file?(&1.path))
      |> Enum.sort_by(& &1.path)
      |> Enum.map(&%{path: &1.path, size: &1.size})

    %{
      nyaa_id: torrent.id,
      title: torrent.title,
      magnet_uri: torrent.magnet_uri,
      files: files
    }
  end

  defp show_detail(show) do
    show
    |> show_summary()
    |> Map.put(
      :releases,
      show.releases
      |> Enum.sort_by(&release_sort_key/1)
      |> Enum.map(&release/1)
    )
  end

  defp show_summary(show) do
    metadata = mapped_metadata(show)

    %{
      id: show.id,
      slug: show.slug,
      title: show.name,
      synopsis: first_present(metadata.overview, show.synopsis),
      media_type: metadata.media_type,
      tvdb_id: metadata.tvdb_id,
      poster_url: first_present(metadata.poster_url, show.image_url),
      fanart_url: first_present(metadata.fanart_url, metadata.poster_url, show.image_url),
      latest_episode: normalize_episode_name(show.latest_episode)
    }
  end

  defp mapped_metadata(%{mapping: %{tvdb_type: :series, tvdb_series: series}} = show)
       when not is_nil(series) do
    poster =
      show.name
      |> season_number()
      |> season_poster(series.seasons)
      |> first_present(series.poster_url, series.image_url)

    %{
      media_type: :series,
      tvdb_id: series.id,
      overview: series.overview,
      poster_url: poster,
      fanart_url: series.fanart_url
    }
  end

  defp mapped_metadata(%{mapping: %{tvdb_type: :movie, tvdb_movie: movie}})
       when not is_nil(movie) do
    %{
      media_type: :movie,
      tvdb_id: movie.id,
      overview: movie.overview,
      poster_url: movie.image_url,
      fanart_url: nil
    }
  end

  defp mapped_metadata(_show) do
    %{media_type: nil, tvdb_id: nil, overview: nil, poster_url: nil, fanart_url: nil}
  end

  defp release(release) do
    %{
      id: release.id,
      kind: release.kind,
      name: release.name,
      episode: release.episode,
      release_date: iso_date(release.source_date),
      released_at: iso_datetime(release.released_at),
      downloads:
        release.downloads
        |> Enum.sort_by(&resolution_sort_key/1)
        |> Enum.map(&download/1)
    }
  end

  defp download(download) do
    %{
      id: download.id,
      resolution: download.resolution,
      torrent_url: download.torrent_url,
      magnet_uri: Magnet.canonicalize_or_original(download.magnet_uri)
    }
  end

  defp schedule_entry(entry) do
    show = if match?(%Show{}, entry.show), do: show_summary(entry.show)

    %{
      id: entry.id,
      slug: entry.slug,
      title: entry.title,
      weekday: entry.weekday,
      scheduled_time: Time.to_iso8601(entry.scheduled_time),
      timezone: "Etc/UTC",
      aired: entry.aired,
      show: show,
      poster_url: first_present(show && show.poster_url, entry.image_url),
      fanart_url: show && show.fanart_url
    }
  end

  defp season_poster(nil, _seasons), do: nil
  defp season_poster(1, _seasons), do: nil

  defp season_poster(number, seasons) do
    seasons
    |> Enum.filter(&(&1.type_name == "Aired Order" and &1.number == number))
    |> Enum.sort_by(& &1.id)
    |> Enum.find_value(& &1.image_url)
  end

  defp season_number(title) do
    case Regex.run(~r/(?:\bS|Season\s+)(\d+)\b/i, title) do
      [_, number] -> String.to_integer(number)
      _match -> nil
    end
  end

  defp release_sort_key(%{kind: :batch} = release),
    do: {0, sort_timestamp(release.released_at), release.name}

  defp release_sort_key(release),
    do: {1, sort_timestamp(release.released_at), release.name}

  defp sort_timestamp(nil), do: 0
  defp sort_timestamp(datetime), do: -DateTime.to_unix(datetime, :microsecond)

  defp resolution_sort_key(download) do
    case Integer.parse(download.resolution) do
      {resolution, _suffix} -> {resolution, download.resolution}
      :error -> {0, download.resolution}
    end
  end

  defp schedule_sort_key(entry) do
    {weekday_number(entry.weekday), Time.to_seconds_after_midnight(entry.scheduled_time),
     entry.title}
  end

  defp weekday_number(weekday) do
    Enum.find_index(
      ~w(Monday Tuesday Wednesday Thursday Friday Saturday Sunday),
      &(&1 == weekday)
    ) || 7
  end

  defp video_file?(path) do
    path
    |> Path.extname()
    |> String.downcase()
    |> then(&(&1 in @video_extensions))
  end

  defp normalize_episode_name(nil), do: nil
  defp normalize_episode_name(name), do: Regex.replace(~r/v\d$/, name, "")

  defp normalize_search(value) when is_binary(value) do
    case value |> String.trim() |> String.downcase() do
      "" -> nil
      query -> query
    end
  end

  defp normalize_search(_value), do: nil

  defp maybe_search(query, nil), do: query

  defp maybe_search(query, search) do
    Ash.Query.filter(query, expr(contains(string_downcase(name), ^search)))
  end

  defp iso_date(nil), do: nil
  defp iso_date(date), do: Date.to_iso8601(date)
  defp iso_datetime(nil), do: nil
  defp iso_datetime(datetime), do: DateTime.to_iso8601(datetime)

  defp first_present(values) when is_list(values), do: Enum.find(values, &present?/1)
  defp first_present(first, second), do: first_present([first, second])
  defp first_present(first, second, third), do: first_present([first, second, third])

  defp present?(value), do: is_binary(value) and String.trim(value) != ""
end
