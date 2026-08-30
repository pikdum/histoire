defmodule AnimeData.TVDB.WebSearchTest do
  use ExUnit.Case, async: false

  alias AnimeData.TVDB.WebSearch

  setup do
    previous_key = Application.get_env(:anime_data, :brave_search_api_key)
    Application.delete_env(:anime_data, :brave_search_api_key)

    on_exit(fn ->
      if is_nil(previous_key) do
        Application.delete_env(:anime_data, :brave_search_api_key)
      else
        Application.put_env(:anime_data, :brave_search_api_key, previous_key)
      end
    end)
  end

  test "requires TVDB search first and permits only one web-search attempt" do
    :ok = WebSearch.begin_research()

    assert WebSearch.search("Kimiai") == {:error, :tvdb_search_required_before_web_search}

    :ok = WebSearch.mark_tvdb_searched()

    assert WebSearch.search("Kimiai") == {:error, :missing_brave_search_api_key}
    assert WebSearch.search("Kimiai") == {:error, :web_search_limit_reached}
  end

  test "keeps the useful fields from Brave web results" do
    results = [
      %{
        "url" => "https://thetvdb.com/series/kimiai-anime",
        "title" => "Kimiai - TheTVDB.com",
        "description" => "The matching anime series.",
        "extra_snippets" => ["Unused detail"]
      }
    ]

    assert WebSearch.parse_results(results) == [
             %{
               "title" => "Kimiai - TheTVDB.com",
               "url" => "https://thetvdb.com/series/kimiai-anime",
               "snippet" => "The matching anime series."
             }
           ]
  end
end
