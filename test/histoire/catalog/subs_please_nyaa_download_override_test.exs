defmodule Histoire.Catalog.SubsPleaseNyaaDownloadOverrideTest do
  use Histoire.DataCase, async: true

  alias Histoire.Catalog.SubsPleaseNyaaDownloadOverride
  alias Histoire.Nyaa.Enrichment
  alias Histoire.SubsPlease.{Download, Release, Show}

  test "validates cached Nyaa torrents and upserts one override per download" do
    now = ~U[2026-08-30 12:00:00Z]

    show =
      Show.upsert!(%{id: 128, slug: "maiko-san", name: "Maiko-san", fetched_at: now})

    release =
      Release.upsert!(%{
        show_id: show.id,
        kind: :batch,
        name: "Maiko-san - 01-12",
        episode: "01-12",
        released_at: now
      })

    download =
      Download.upsert!(%{
        release_id: release.id,
        resolution: "720",
        torrent_url: "https://nyaa.si/view/1511343/torrent"
      })

    for id <- [1_490_918, 1_490_919] do
      {:ok, _torrent} =
        Enrichment.store(id, "https://nyaa.si/view/#{id}", %{
          title: "Nyaa #{id}",
          magnet_uri: "magnet:?xt=urn:btih:#{id}",
          files: [%{path: "#{id}.mkv", size: "1 GiB"}]
        })
    end

    assert %SubsPleaseNyaaDownloadOverride{nyaa_id: 1_490_918} =
             SubsPleaseNyaaDownloadOverride.put!(%{
               subsplease_download_id: download.id,
               nyaa_id: 1_490_918
             })

    assert %SubsPleaseNyaaDownloadOverride{nyaa_id: 1_490_919} =
             SubsPleaseNyaaDownloadOverride.put!(%{
               subsplease_download_id: download.id,
               nyaa_id: 1_490_919
             })

    assert %SubsPleaseNyaaDownloadOverride{nyaa_id: 1_490_919} =
             SubsPleaseNyaaDownloadOverride.get_by_subsplease_download_id!(download.id)
  end
end
