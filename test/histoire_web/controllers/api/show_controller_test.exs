defmodule HistoireWeb.Api.ShowControllerTest do
  use HistoireWeb.ConnCase, async: true

  alias Histoire.Catalog.SubsPleaseTVDBShowMatch, as: Mapping
  alias Histoire.SubsPlease.{Download, Release, ScheduleEntry, Show}
  alias Histoire.TVDB.{Artwork, Movie, MovieArtwork, Season, Series}

  setup do
    now = ~U[2026-08-30 12:00:00Z]

    show =
      Show.upsert!(%{
        id: 824,
        slug: "example-s2",
        name: "Example S2",
        synopsis: "SubsPlease synopsis",
        image_url: "https://subsplease.test/poster.jpg",
        fetched_at: now
      })

    Series.upsert!(%{
      id: 427_831,
      name: "Example",
      overview: "TVDB Japanese overview",
      original_language: "jpn",
      raw: %{
        "translations" => %{
          "overviewTranslations" => [
            %{"language" => "jpn", "overview" => "TVDB Japanese overview"},
            %{"language" => "eng", "overview" => "TVDB English overview"}
          ]
        }
      },
      image_url: "https://tvdb.test/series.jpg",
      fetched_at: now
    })

    Season.upsert!(%{
      id: 2_032_519,
      series_id: 427_831,
      number: 2,
      type_name: "Aired Order",
      image_url: "https://tvdb.test/season-2.jpg"
    })

    Artwork.upsert!(%{
      id: 64_137_577,
      series_id: 427_831,
      artwork_type: 3,
      image_url: "https://tvdb.test/fanart.jpg",
      includes_text: false,
      width: 1920,
      height: 1080
    })

    show.id
    |> then(&Mapping.upsert_subsplease!(%{subsplease_id: &1}))
    |> Mapping.record_result!(%{
      tvdb_id: 427_831,
      tvdb_type: :series,
      status: :matched,
      match_method: :manual,
      matched_at: now
    })

    release =
      Release.upsert!(%{
        show_id: show.id,
        kind: :episode,
        name: "Example S2 - 12v2",
        episode: "12v2",
        source_date: ~D[2026-08-30],
        released_at: now
      })

    Download.upsert!(%{
      release_id: release.id,
      resolution: "1080",
      torrent_url: "https://nyaa.si/view/1/torrent",
      magnet_uri:
        "magnet:?xt=urn:btih:VS6Z5XS3WA2W6JGECOMYC5N2KVRIBJBD" <>
          "&dn=Example%20S2%20-%2012&xl=1234" <>
          "&tr=http%3A%2F%2Fnyaa.tracker.wf%3A7777%2Fannounce" <>
          "&tr=udp%3A%2F%2Ftracker.opentrackr.org%3A1337%2Fannounce" <>
          "&tr=udp%3A%2F%2Fopen.stealth.si%3A80%2Fannounce" <>
          "&tr=udp%3A%2F%2Fexodus.desync.com%3A6969%2Fannounce" <>
          "&tr=udp%3A%2F%2Ftracker.torrent.eu.org%3A451%2Fannounce" <>
          "&tr=udp%3A%2F%2Fextra.invalid%3A80%2Fannounce"
    })

    ScheduleEntry.upsert!(%{
      show_id: show.id,
      slug: show.slug,
      title: show.name,
      weekday: "Sunday",
      scheduled_time: ~T[14:30:00],
      observed_at: now
    })

    %{show: show}
  end

  test "returns client-ready shows with mapped art and canonical magnets", %{
    conn: conn,
    show: show
  } do
    summary =
      conn |> get(~p"/api/v1/shows") |> json_response(200) |> get_in(["data", Access.at(0)])

    assert summary["id"] == show.id
    assert summary["title"] == "Example S2"
    assert summary["synopsis"] == "TVDB English overview"
    assert summary["poster_url"] == "https://tvdb.test/season-2.jpg"
    assert summary["fanart_url"] == "https://tvdb.test/fanart.jpg"
    assert summary["latest_episode"] == "Example S2 - 12"

    detail = conn |> recycle() |> get(~p"/api/v1/shows/#{show.id}") |> json_response(200)

    magnet =
      get_in(detail, ["data", "releases", Access.at(0), "downloads", Access.at(0), "magnet_uri"])

    assert magnet =~ "urn:btih:acbd9ede5bb0356f24c413998175ba556280a423"
    refute magnet =~ "xl="
    assert length(Regex.scan(~r/(?:^|&)tr=/, magnet)) == 5
  end

  test "falls back to the English SubsPlease synopsis before translations are refreshed", %{
    conn: conn
  } do
    Series.upsert!(%{
      id: 427_831,
      name: "Example",
      overview: "TVDB Japanese overview",
      original_language: "jpn",
      raw: %{"overviewTranslations" => ["jpn", "eng"]},
      image_url: "https://tvdb.test/series.jpg",
      fetched_at: ~U[2026-08-30 12:00:00Z]
    })

    summary =
      conn |> get(~p"/api/v1/shows") |> json_response(200) |> get_in(["data", Access.at(0)])

    assert summary["synopsis"] == "SubsPlease synopsis"
  end

  test "returns English metadata and distinct artwork for mapped movies", %{
    conn: conn,
    show: show
  } do
    Movie.upsert!(%{
      id: 199_463,
      name: "映画 バクテン!!",
      overview: nil,
      image_url: "https://tvdb.test/movie-default.jpg",
      original_language: "jpn",
      raw: %{
        "translations" => %{
          "overviewTranslations" => [
            %{"language" => "eng", "overview" => "TVDB English movie overview"}
          ]
        }
      },
      fetched_at: ~U[2026-08-30 12:00:00Z]
    })

    MovieArtwork.upsert!(%{
      id: 63_982_338,
      movie_id: 199_463,
      artwork_type: 14,
      image_url: "https://tvdb.test/movie-poster.jpg",
      score: 100_000
    })

    MovieArtwork.upsert!(%{
      id: 63_982_339,
      movie_id: 199_463,
      artwork_type: 15,
      image_url: "https://tvdb.test/movie-background.jpg",
      score: 100_000
    })

    show.id
    |> Mapping.get_by_subsplease_id!()
    |> Mapping.record_result!(%{
      tvdb_id: 199_463,
      tvdb_type: :movie,
      status: :matched,
      match_method: :manual,
      matched_at: ~U[2026-08-30 12:00:00Z]
    })

    summary =
      conn |> get(~p"/api/v1/shows") |> json_response(200) |> get_in(["data", Access.at(0)])

    assert summary["media_type"] == "movie"
    assert summary["synopsis"] == "TVDB English movie overview"
    assert summary["poster_url"] == "https://tvdb.test/movie-poster.jpg"
    assert summary["fanart_url"] == "https://tvdb.test/movie-background.jpg"
  end

  test "returns the recurring schedule in UTC with resolved show metadata", %{conn: conn} do
    entry =
      conn |> get(~p"/api/v1/schedule") |> json_response(200) |> get_in(["data", Access.at(0)])

    assert entry["weekday"] == "Sunday"
    assert entry["scheduled_time"] == "14:30:00"
    assert entry["timezone"] == "Etc/UTC"
    assert entry["show"]["title"] == "Example S2"
  end
end
