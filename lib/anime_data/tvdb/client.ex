defmodule AnimeData.TVDB.Client do
  @moduledoc false

  alias AnimeData.TVDB.{RateLimiter, TokenStore}

  @api_base "https://api4.thetvdb.com/v4"
  @pin "hello world"

  def login(api_key) do
    request(:post, "/login", json: %{apikey: api_key, pin: @pin}, authenticated?: false)
    |> case do
      {:ok, %{"token" => token}} when is_binary(token) -> {:ok, token}
      {:ok, _body} -> {:error, :invalid_login_response}
      error -> error
    end
  end

  def search(query) when is_binary(query), do: get("/search", query: query)
  def fetch_series(id), do: get("/series/#{id}/extended")
  def fetch_series_by_slug(slug), do: get("/series/slug/#{slug}")
  def fetch_movie(id), do: get("/movies/#{id}/extended")

  def fetch_artworks(id) do
    with {:ok, data} <- get("/series/#{id}/artworks"),
         {:ok, artworks} <- required_list(data, "artworks") do
      {:ok, artworks}
    end
  end

  defp get(path, params \\ []) do
    request(:get, path, params: params)
  end

  defp request(method, path, opts) do
    authenticated? = Keyword.get(opts, :authenticated?, true)

    with {:ok, token} <- maybe_token(authenticated?),
         result <- do_request(method, path, token, opts),
         result <- maybe_retry_unauthorized(result, method, path, opts, authenticated?) do
      result
    end
  end

  defp do_request(method, path, token, opts) do
    :ok = RateLimiter.wait()

    request_opts =
      opts
      |> Keyword.drop([:authenticated?])
      |> Keyword.put(:url, @api_base <> path)
      |> Keyword.put(:method, method)
      |> Keyword.put(:receive_timeout, 30_000)
      |> Keyword.put(:retry, :transient)
      |> Keyword.put(:max_retries, 2)
      |> maybe_put_auth(token)

    case Req.request(request_opts) do
      {:ok, %{status: status, body: %{"data" => data}}} when status in 200..299 -> {:ok, data}
      {:ok, %{status: status}} -> {:error, {:http_status, status, path}}
      {:error, reason} -> {:error, {:request_failed, path, reason}}
    end
  end

  defp maybe_retry_unauthorized({:error, {:http_status, 401, _}}, method, path, opts, true) do
    TokenStore.invalidate()

    with {:ok, token} <- TokenStore.token() do
      do_request(method, path, token, opts)
    end
  end

  defp maybe_retry_unauthorized(result, _method, _path, _opts, _authenticated?), do: result

  defp maybe_token(false), do: {:ok, nil}
  defp maybe_token(true), do: TokenStore.token()

  defp maybe_put_auth(opts, nil), do: opts
  defp maybe_put_auth(opts, token), do: Keyword.put(opts, :auth, {:bearer, token})

  defp required_list(map, key) do
    case Map.fetch(map, key) do
      {:ok, value} when is_list(value) -> {:ok, value}
      {:ok, value} -> {:error, {:invalid_collection, key, value}}
      :error -> {:error, {:missing_collection, key}}
    end
  end
end
