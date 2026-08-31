defmodule Histoire.Nyaa.Parser do
  @moduledoc false

  alias Histoire.Torrents.Magnet

  def torrent_id(url) when is_binary(url) do
    case Regex.run(~r{https?://(?:www\.)?nyaa\.si/view/(\d+)(?:/torrent)?(?:[/?#]|$)}, url) do
      [_, id] -> parse_positive_integer(id)
      _match -> {:error, :invalid_nyaa_url}
    end
  end

  def torrent_id(_url), do: {:error, :invalid_nyaa_url}

  def torrent(html) when is_binary(html) do
    document = LazyHTML.from_document(html)

    with {:ok, title} <- first_text(document, ".panel > .panel-heading > h3.panel-title"),
         {:ok, magnet_uri} <-
           first_attribute(document, "a.card-footer-item[href^='magnet:']", "href"),
         {:ok, canonical_magnet} <- Magnet.canonicalize(magnet_uri),
         files when files != [] <- files(document) do
      {:ok, %{title: title, magnet_uri: canonical_magnet, files: files}}
    else
      [] -> {:error, :missing_files}
      {:error, _reason} = error -> error
    end
  end

  def torrent(_html), do: {:error, :invalid_html}

  defp files(document) do
    document
    |> LazyHTML.query(".torrent-file-list li:has(> i.fa-file)")
    |> Enum.map(fn node ->
      size =
        node
        |> LazyHTML.query("span.file-size")
        |> LazyHTML.text()
        |> String.trim()
        |> String.trim_leading("(")
        |> String.trim_trailing(")")

      path =
        node
        |> LazyHTML.text()
        |> String.trim()
        |> String.replace_suffix(" (#{size})", "")

      %{path: path, size: empty_to_nil(size)}
    end)
    |> Enum.reject(&(&1.path == ""))
  end

  defp first_text(document, selector) do
    case document |> LazyHTML.query(selector) |> Enum.take(1) do
      [node] ->
        case node |> LazyHTML.text() |> String.trim() do
          "" -> {:error, :missing_title}
          title -> {:ok, title}
        end

      [] ->
        {:error, :missing_title}
    end
  end

  defp first_attribute(document, selector, attribute) do
    case document |> LazyHTML.query(selector) |> LazyHTML.attribute(attribute) do
      [value | _rest] -> {:ok, value}
      [] -> {:error, :missing_magnet}
    end
  end

  defp parse_positive_integer(value) do
    case Integer.parse(value) do
      {id, ""} when id > 0 -> {:ok, id}
      _result -> {:error, :invalid_nyaa_url}
    end
  end

  defp empty_to_nil(""), do: nil
  defp empty_to_nil(value), do: value
end
