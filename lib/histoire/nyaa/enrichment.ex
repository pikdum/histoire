defmodule Histoire.Nyaa.Enrichment do
  @moduledoc "Fetches and caches the Nyaa metadata needed for batch playback."

  alias Histoire.Nyaa.{Client, File, Parser, Torrent}

  def get_or_fetch(id) when is_integer(id) and id > 0 do
    case Torrent.get_by_id(id, load: :files) do
      {:ok, %Torrent{files: [_file | _rest]} = torrent} -> {:ok, torrent}
      {:ok, %Torrent{}} -> fetch_and_store(id)
      {:ok, nil} -> fetch_and_store(id)
      {:error, reason} -> {:error, reason}
    end
  end

  def get_or_fetch(torrent_url) when is_binary(torrent_url) do
    with {:ok, id} <- Parser.torrent_id(torrent_url) do
      get_or_fetch(id)
    end
  end

  def get_or_fetch(_target), do: {:error, :invalid_nyaa_url}

  defp fetch_and_store(id) do
    page_url = "https://nyaa.si/view/#{id}"

    with {:ok, html} <- Client.fetch_torrent(id),
         {:ok, parsed} <- Parser.torrent(html) do
      store(id, page_url, parsed)
    end
  end

  @doc false
  def store(id, page_url, parsed) do
    Ash.transact([Torrent, File], fn ->
      with {:ok, torrent} <-
             Torrent.upsert(%{
               id: id,
               title: parsed.title,
               page_url: page_url,
               magnet_uri: parsed.magnet_uri,
               fetched_at: DateTime.utc_now()
             }),
           :ok <- upsert_files(torrent.id, parsed.files),
           {:ok, loaded} <- Ash.load(torrent, :files) do
        loaded
      end
    end)
  end

  defp upsert_files(torrent_id, files) do
    Enum.reduce_while(files, :ok, fn file, :ok ->
      case File.upsert(Map.put(file, :torrent_id, torrent_id)) do
        {:ok, _file} -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end
end
