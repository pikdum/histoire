defmodule AnimeData.SubsPlease.Client do
  @moduledoc false

  alias AnimeData.SubsPlease.{Parser, RateLimiter}

  @base_url "https://subsplease.org"
  @timezone "Etc/UTC"

  def fetch_index do
    with {:ok, html} <- get("/shows/") do
      {:ok, Parser.index(html)}
    end
  end

  def fetch_show_page(slug) do
    with {:ok, html} <- get("/shows/#{slug}/") do
      Parser.show_page(html, slug)
    end
  end

  def fetch_releases(show_id) do
    with {:ok, payload} <- get_json("/api/", f: "show", tz: @timezone, sid: show_id) do
      {:ok, Parser.releases(payload)}
    end
  end

  def fetch_latest do
    with {:ok, payload} <- get_json("/api/", f: "latest", tz: @timezone) do
      {:ok, Parser.latest(payload)}
    end
  end

  def fetch_schedule do
    with {:ok, payload} <- get_json("/api/", f: "schedule", tz: @timezone) do
      Parser.schedule(payload)
    end
  end

  defp get_json(path, params) do
    with {:ok, body} <- get(path, params),
         {:ok, payload} <- decode_json(body) do
      {:ok, payload}
    end
  end

  defp decode_json(body) when is_map(body), do: {:ok, body}
  defp decode_json(body) when is_binary(body), do: Jason.decode(body)

  defp get(path, params \\ []) do
    :ok = RateLimiter.wait()

    request = [
      url: @base_url <> path,
      params: params,
      headers: [{"user-agent", "anime-data/0.1 (+local metadata mirror)"}],
      receive_timeout: 30_000,
      retry: :transient,
      max_retries: 2
    ]

    case Req.get(request) do
      {:ok, %{status: status, body: body}} when status in 200..299 -> {:ok, body}
      {:ok, %{status: status}} -> {:error, {:http_status, status, path}}
      {:error, reason} -> {:error, {:request_failed, path, reason}}
    end
  end
end
