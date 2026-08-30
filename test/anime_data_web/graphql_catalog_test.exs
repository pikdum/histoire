defmodule AnimeDataWeb.GraphqlCatalogTest do
  use AnimeDataWeb.ConnCase, async: true

  alias AnimeData.Catalog.Mapping
  alias AnimeData.SubsPlease.Importer
  alias AnimeData.TVDB.{Movie, Series}

  test "joins a mapping to both source schemas", %{conn: conn} do
    show_id = System.unique_integer([:positive])
    tvdb_id = System.unique_integer([:positive])

    assert {:ok, _show} =
             Importer.show(%{
               id: show_id,
               slug: "graphql-#{show_id}",
               name: "SubsPlease Name",
               fetched_at: ~U[2026-08-30 00:00:00Z]
             })

    assert {:ok, 0} = Importer.releases(show_id, [])

    assert {:ok, _series} =
             Series.upsert(%{
               id: tvdb_id,
               name: "TVDB Name",
               fetched_at: ~U[2026-08-30 00:00:00Z]
             })

    mapping = Mapping.get_by_subsplease_id!(show_id)

    assert {:ok, mapping} =
             Mapping.set_tvdb(mapping, %{tvdb_id: tvdb_id, tvdb_type: :series})

    query = """
    query Mapping($id: ID!) {
      mapping(id: $id) {
        status
        subspleaseShow { name }
        tvdbSeries { name }
      }
    }
    """

    response =
      conn
      |> post(~p"/gql/", %{query: query, variables: %{id: mapping.id}})
      |> json_response(200)

    assert response == %{
             "data" => %{
               "mapping" => %{
                 "status" => "matched",
                 "subspleaseShow" => %{"name" => "SubsPlease Name"},
                 "tvdbSeries" => %{"name" => "TVDB Name"}
               }
             }
           }
  end

  test "joins a movie mapping only to the TVDB movie", %{conn: conn} do
    show_id = System.unique_integer([:positive])
    tvdb_id = System.unique_integer([:positive])

    assert {:ok, _show} =
             Importer.show(%{
               id: show_id,
               slug: "movie-#{show_id}",
               name: "SubsPlease Movie",
               fetched_at: ~U[2026-08-30 00:00:00Z]
             })

    assert {:ok, 0} = Importer.releases(show_id, [])

    assert {:ok, _movie} =
             Movie.upsert(%{
               id: tvdb_id,
               name: "TVDB Movie",
               fetched_at: ~U[2026-08-30 00:00:00Z]
             })

    mapping = Mapping.get_by_subsplease_id!(show_id)

    assert {:ok, mapping} =
             Mapping.set_tvdb(mapping, %{tvdb_id: tvdb_id, tvdb_type: :movie})

    query = """
    query Mapping($id: ID!) {
      mapping(id: $id) {
        tvdbType
        tvdbSeries { name }
        tvdbMovie { name }
      }
    }
    """

    response =
      conn
      |> post(~p"/gql/", %{query: query, variables: %{id: mapping.id}})
      |> json_response(200)

    assert response == %{
             "data" => %{
               "mapping" => %{
                 "tvdbType" => "movie",
                 "tvdbSeries" => nil,
                 "tvdbMovie" => %{"name" => "TVDB Movie"}
               }
             }
           }
  end
end
