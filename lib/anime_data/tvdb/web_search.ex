defmodule AnimeData.TVDB.WebSearch do
  @moduledoc false

  @endpoint "https://api.search.brave.com/res/v1/web/search"
  @tvdb_searched_key {__MODULE__, :tvdb_searched?}
  @web_searched_key {__MODULE__, :web_searched?}

  def begin_research do
    Process.delete(@tvdb_searched_key)
    Process.delete(@web_searched_key)
    :ok
  end

  def mark_tvdb_searched do
    Process.put(@tvdb_searched_key, true)
    :ok
  end

  def search(query) when is_binary(query) do
    with :ok <- allow_search(),
         {:ok, api_key} <- api_key(),
         {:ok, response} <-
           Req.get(@endpoint,
             params: [q: query, count: 5],
             headers: [
               {"accept", "application/json"},
               {"x-subscription-token", api_key}
             ],
             receive_timeout: 15_000,
             retry: false
           ) do
      parse_response(response)
    end
  end

  def parse_results(results) when is_list(results) do
    Enum.map(results, fn result ->
      %{
        "title" => result["title"] || "",
        "url" => result["url"] || "",
        "snippet" => result["description"] || ""
      }
    end)
  end

  defp api_key do
    case Application.get_env(:anime_data, :brave_search_api_key) do
      key when is_binary(key) and key != "" -> {:ok, key}
      _missing -> {:error, :missing_brave_search_api_key}
    end
  end

  defp allow_search do
    cond do
      Process.get(@tvdb_searched_key) != true ->
        {:error, :tvdb_search_required_before_web_search}

      Process.get(@web_searched_key) ->
        {:error, :web_search_limit_reached}

      true ->
        Process.put(@web_searched_key, true)
        :ok
    end
  end

  defp parse_response(%{status: status, body: body}) when status in 200..299 do
    {:ok, parse_results(get_in(body, ["web", "results"]) || [])}
  end

  defp parse_response(%{status: status}), do: {:error, {:http_status, status, @endpoint}}
end
