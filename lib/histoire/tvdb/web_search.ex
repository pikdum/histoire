defmodule Histoire.TVDB.WebSearch do
  @moduledoc false

  @endpoint "https://api.search.brave.com/res/v1/web/search"

  def search(query) when is_binary(query) do
    with {:ok, api_key} <- api_key(),
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
    case Application.get_env(:histoire, :brave_search_api_key) do
      key when is_binary(key) and key != "" -> {:ok, key}
      _missing -> {:error, :missing_brave_search_api_key}
    end
  end

  defp parse_response(%{status: status, body: body}) when status in 200..299 do
    {:ok, parse_results(get_in(body, ["web", "results"]) || [])}
  end

  defp parse_response(%{status: status}), do: {:error, {:http_status, status, @endpoint}}
end
