defmodule Histoire.TVDB.ImporterTest do
  use Histoire.DataCase, async: true

  alias Histoire.TVDB.{Artwork, Importer, Movie, MovieArtwork, Season, Series}

  test "upserts a source-shaped series with seasons and artworks idempotently" do
    series = %{
      "id" => 427_831,
      "name" => "アクロトリップ",
      "slug" => "acro-trip",
      "overview" => "A magical girl comedy.",
      "image" => "https://artworks.thetvdb.com/poster.jpg",
      "firstAired" => "2024-10-02",
      "lastAired" => "2024-12-18",
      "year" => "2024",
      "originalCountry" => "jpn",
      "originalLanguage" => "jpn",
      "score" => 1285,
      "status" => %{"id" => 2, "name" => "Ended"},
      "seasons" => [
        %{
          "id" => 2_032_519,
          "number" => 0,
          "type" => %{"id" => 1, "name" => "Aired Order"}
        }
      ]
    }

    artworks = [
      %{
        "id" => 64_137_577,
        "type" => 3,
        "image" => "https://artworks.thetvdb.com/background.jpg",
        "thumbnail" => "https://artworks.thetvdb.com/background_t.jpg",
        "score" => 100_000,
        "width" => 1920,
        "height" => 1080
      }
    ]

    assert {:ok, %Series{id: 427_831}} = Importer.series(series, artworks)
    assert {:ok, %Series{id: 427_831}} = Importer.series(series, artworks)

    assert %Series{
             first_aired: ~D[2024-10-02],
             status_name: "Ended",
             original_language: "jpn"
           } = Series.get_by_id!(427_831)

    assert [%Season{id: 2_032_519, type_name: "Aired Order"}] = Season.list!()
    assert [%Artwork{id: 64_137_577, artwork_type: 3, width: 1920}] = Artwork.list!()
  end

  test "removes child rows no longer returned by the source" do
    series = %{"id" => 1, "name" => "Example", "seasons" => []}
    artwork = %{"id" => 2, "image" => "https://example.test/image.jpg"}

    assert {:ok, _series} = Importer.series(series, [artwork])
    assert [_artwork] = Artwork.list!()
    assert {:ok, _series} = Importer.series(series, [])
    assert [] = Artwork.list!()
  end

  test "does not modify a series when its seasons collection is missing" do
    original = %{"id" => 1, "name" => "Original", "seasons" => []}

    assert {:ok, _series} = Importer.series(original, [])

    assert {:error, {:missing_collection, "seasons"}} =
             Importer.series(%{"id" => 1, "name" => "Changed"}, [])

    assert %Series{name: "Original"} = Series.get_by_id!(1)
  end

  test "mirrors a movie extended response" do
    movie = %{
      "id" => 199_463,
      "name" => "映画 バクテン!!",
      "slug" => "199463-",
      "overview" => nil,
      "image" => "https://artworks.thetvdb.com/movie-poster.jpg",
      "year" => "2022",
      "first_release" => %{"country" => "jpn", "date" => "2022-06-02"},
      "originalCountry" => "jpn",
      "originalLanguage" => "jpn",
      "runtime" => 90,
      "score" => 1048,
      "status" => %{"id" => 5, "name" => "Released"},
      "translations" => %{
        "overviewTranslations" => [
          %{"language" => "eng", "overview" => "The gymnastics team reunites."}
        ]
      },
      "artworks" => [
        %{
          "id" => 63_982_338,
          "type" => 14,
          "image" => "https://artworks.thetvdb.com/movie-poster.jpg",
          "score" => 100_000,
          "width" => 680,
          "height" => 1000
        },
        %{
          "id" => 63_982_339,
          "type" => 15,
          "image" => "https://artworks.thetvdb.com/movie-background.jpg",
          "score" => 99_000,
          "width" => 1920,
          "height" => 1080
        }
      ]
    }

    assert {:ok, %Movie{id: 199_463}} = Importer.movie(movie)

    updated =
      movie
      |> Map.put("name", "Backflip!! Movie")
      |> Map.put("runtime", 91)
      |> Map.put("artworks", [
        movie
        |> Map.fetch!("artworks")
        |> Enum.at(1)
        |> Map.put("score", 100_000)
      ])

    assert {:ok, %Movie{id: 199_463}} = Importer.movie(updated)

    assert %Movie{
             name: "Backflip!! Movie",
             first_released: ~D[2022-06-02],
             runtime: 91,
             status_name: "Released",
             raw: %{"translations" => %{"overviewTranslations" => [_english]}}
           } = Movie.get_by_id!(199_463)

    assert [
             %MovieArtwork{
               id: 63_982_339,
               artwork_type: 15,
               score: 100_000.0,
               width: 1920
             }
           ] = MovieArtwork.list!()

    assert {:ok, %Movie{id: 199_463}} =
             updated
             |> Map.put("artworks", nil)
             |> Importer.movie()

    assert MovieArtwork.list!() == []
  end
end
