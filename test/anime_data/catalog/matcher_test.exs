defmodule AnimeData.Catalog.MatcherTest do
  use ExUnit.Case, async: true

  test "exposes only the two read-only TVDB research tools" do
    tools = AshAi.Info.tools(AnimeData.TVDB)

    assert Enum.map(tools, & &1.name) == [:search_tvdb_series, :get_tvdb_series]
    assert Enum.all?(tools, &(&1.resource == AnimeData.TVDB.Lookup))
  end
end
