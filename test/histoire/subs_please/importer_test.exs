defmodule Histoire.SubsPlease.ImporterTest do
  use Histoire.DataCase, async: true

  alias Histoire.Catalog.SubsPleaseTVDBShowMatch, as: Mapping
  alias Histoire.SubsPlease.{Importer, Release, Show}

  test "upserts a source-shaped show, mapping, release, and downloads idempotently" do
    show_attributes = %{
      id: 824,
      slug: "acro-trip",
      name: "Acro Trip",
      synopsis: "A magical girl comedy.",
      image_url: "https://subsplease.org/acro.jpg",
      fetched_at: ~U[2026-08-30 00:00:00Z],
      raw: %{"slug" => "acro-trip"}
    }

    releases = [
      %{
        kind: :episode,
        name: "Acro Trip - 12",
        raw: %{
          "time" => "12/11/24",
          "release_date" => "Wed, 11 Dec 2024 14:17:56 +0000",
          "episode" => "12",
          "downloads" => [
            %{
              "res" => "1080",
              "torrent" => "https://nyaa.si/view/1/torrent",
              "magnet" => "magnet:?xt=urn:btih:one"
            }
          ]
        }
      }
    ]

    assert {:ok, %Show{id: 824}} = Importer.show(show_attributes)
    assert {:error, _error} = Mapping.get_by_subsplease_id(824)
    assert {:ok, 1} = Importer.releases(824, releases)
    assert {:ok, 1} = Importer.releases(824, releases)

    assert %Mapping{subsplease_id: 824, tvdb_id: nil} =
             Mapping.get_by_subsplease_id!(824)

    assert [%Release{episode: "12", source_date: ~D[2024-12-11]} = release] = Release.list!()

    assert [%{resolution: "1080", magnet_uri: "magnet:?xt=urn:btih:one"}] =
             Ash.load!(release, :downloads).downloads
  end

  test "does not replace downloads when a release payload omits the collection" do
    assert {:ok, _show} =
             Importer.show(%{
               id: 824,
               slug: "acro-trip",
               name: "Acro Trip",
               fetched_at: ~U[2026-08-30 00:00:00Z]
             })

    release = %{
      kind: :episode,
      name: "Acro Trip - 12",
      raw: %{
        "time" => "12/11/24",
        "release_date" => "Wed, 11 Dec 2024 14:17:56 +0000",
        "episode" => "12",
        "downloads" => [%{"res" => "1080", "magnet" => "magnet:?xt=urn:btih:one"}]
      }
    }

    assert {:ok, 1} = Importer.releases(824, [release])

    assert {:error, {:missing_collection, "downloads"}} =
             Importer.releases(824, [
               put_in(release, [:raw], Map.delete(release.raw, "downloads"))
             ])

    assert [%Release{} = stored] = Release.list!()
    assert [%{resolution: "1080"}] = Ash.load!(stored, :downloads).downloads
  end
end
