defmodule Histoire.Nyaa.Client do
  @moduledoc false

  alias Histoire.Nyaa.RateLimiter

  @base_url "https://nyaa.si"

  def fetch_torrent(id) when is_integer(id) and id > 0 do
    path = "/view/#{id}"
    :ok = RateLimiter.wait()

    request = [
      url: @base_url <> path,
      headers: [{"user-agent", "histoire/0.1 (+local metadata mirror)"}],
      receive_timeout: 15_000,
      retry: :transient,
      max_retries: 2
    ]

    case Req.get(request) do
      {:ok, %{status: status, body: body}} when status in 200..299 and is_binary(body) ->
        {:ok, body}

      {:ok, %{status: status}} ->
        {:error, {:http_status, status, path}}

      {:error, reason} ->
        {:error, {:request_failed, path, reason}}
    end
  end
end
