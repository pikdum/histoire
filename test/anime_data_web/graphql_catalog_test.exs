defmodule AnimeDataWeb.GraphqlCatalogTest do
  use AnimeDataWeb.ConnCase, async: true

  alias AnimeData.Catalog.Mapping
  alias AnimeData.SubsPlease.Importer
  alias AnimeData.TVDB.Series

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

    assert {:ok, _series} =
             Series.upsert(%{
               id: tvdb_id,
               name: "TVDB Name",
               fetched_at: ~U[2026-08-30 00:00:00Z]
             })

    mapping = Mapping.get_by_subsplease_id!(show_id)
    assert {:ok, mapping} = Mapping.set_tvdb(mapping, %{tvdb_id: tvdb_id})

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
end
