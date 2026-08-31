defmodule HistoireWeb.Api.DownloadControllerTest do
  use HistoireWeb.ConnCase, async: true

  alias Histoire.Catalog.SubsPleaseNyaaDownloadOverride
  alias Histoire.Nyaa.Enrichment
  alias Histoire.SubsPlease.{Download, Release, Show}

  setup do
    now = ~U[2026-08-30 12:00:00Z]

    show =
      Show.upsert!(%{
        id: 128,
        slug: "maiko-san-chi-no-makanai-san",
        name: "Maiko-san Chi no Makanai-san",
        fetched_at: now
      })

    release =
      Release.upsert!(%{
        show_id: show.id,
        kind: :batch,
        name: "Maiko-san Chi no Makanai-san - 01-12",
        episode: "01-12",
        released_at: now
      })

    download =
      Download.upsert!(%{
        release_id: release.id,
        resolution: "1080",
        torrent_url: "https://nyaa.si/view/1511344/torrent"
      })

    {:ok, _old_torrent} =
      Enrichment.store(1_511_344, "https://nyaa.si/view/1511344", %{
        title: "old torrent",
        magnet_uri: "magnet:?xt=urn:btih:old",
        files: [%{path: "wrong-file.mkv", size: "1 GiB"}]
      })

    {:ok, _replacement_torrent} =
      Enrichment.store(1_490_919, "https://nyaa.si/view/1490919", %{
        title: "[SubsPlease] Maiko-san Chi no Makanai-san (1080p) [Batch]",
        magnet_uri: "magnet:?xt=urn:btih:replacement",
        files: [%{path: "Maiko-san Chi no Makanai-san - 01.mkv", size: "1.2 GiB"}]
      })

    SubsPleaseNyaaDownloadOverride.put!(%{
      subsplease_download_id: download.id,
      nyaa_id: 1_490_919,
      note: "The torrent linked by SubsPlease is gone."
    })

    %{download: download}
  end

  test "uses the explicit Nyaa override for a batch download", %{conn: conn, download: download} do
    response =
      conn
      |> get(~p"/api/v1/downloads/#{download.id}/files")
      |> json_response(200)
      |> Map.fetch!("data")

    assert response["nyaa_id"] == 1_490_919
    assert response["title"] =~ "Maiko-san"

    assert response["files"] == [
             %{"path" => "Maiko-san Chi no Makanai-san - 01.mkv", "size" => "1.2 GiB"}
           ]
  end
end
