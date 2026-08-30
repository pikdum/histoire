defmodule AnimeData.SubsPlease.Parser do
  @moduledoc false

  @base_url "https://subsplease.org"

  def index(html) when is_binary(html) do
    html
    |> LazyHTML.from_document()
    |> LazyHTML.query(~s|a[href^="/shows/"]|)
    |> Enum.reduce(%{}, fn node, shows ->
      with [href | _] <- LazyHTML.attribute(node, "href"),
           slug when slug != "" <- slug_from_page(href) do
        name =
          node
          |> LazyHTML.attribute("title")
          |> List.first()
          |> presence(LazyHTML.text(node) |> String.trim())

        Map.put_new(shows, slug, %{slug: slug, name: name})
      else
        _ -> shows
      end
    end)
    |> Map.values()
    |> Enum.sort_by(& &1.slug)
  end

  def show_page(html, slug) when is_binary(html) and is_binary(slug) do
    document = LazyHTML.from_document(html)

    with {:ok, id} <- required_integer_attribute(document, "#show-release-table", "sid"),
         {:ok, name} <- required_text(document, ".entry-title") do
      {:ok,
       %{
         id: id,
         slug: slug,
         name: name,
         synopsis: optional_text(document, ".series-syn p"),
         image_url:
           optional_attribute(document, "#secondary img.img-responsive", "src") |> absolute_url(),
         raw: %{"slug" => slug},
         fetched_at: DateTime.utc_now()
       }}
    end
  end

  def releases(payload) when is_map(payload) do
    [:episode, :batch]
    |> Enum.flat_map(fn kind ->
      payload
      |> Map.get(Atom.to_string(kind), %{})
      |> named_rows()
      |> Enum.map(fn {name, row} -> %{kind: kind, name: name, raw: row} end)
    end)
  end

  def latest(payload) when is_map(payload) do
    payload
    |> named_rows()
    |> Enum.flat_map(fn {name, row} ->
      case slug_from_page(row["page"]) do
        "" -> []
        slug -> [%{name: name, slug: slug, raw: row}]
      end
    end)
  end

  def schedule(%{"schedule" => schedule}) when is_map(schedule) do
    if Enum.all?(schedule, fn {_weekday, entries} -> is_list(entries) end) do
      {:ok,
       Enum.flat_map(schedule, fn {weekday, entries} ->
         Enum.map(entries, &Map.put(&1, "weekday", weekday))
       end)}
    else
      {:error, :invalid_schedule_payload}
    end
  end

  def schedule(_payload), do: {:error, :invalid_schedule_payload}

  def slug_from_page(nil), do: ""

  def slug_from_page(page) when is_binary(page) do
    page
    |> URI.parse()
    |> Map.get(:path)
    |> to_string()
    |> String.trim("/")
    |> String.replace_prefix("shows/", "")
    |> String.split("/", parts: 2)
    |> List.first()
  end

  def absolute_url(nil), do: nil
  def absolute_url("http" <> _rest = url), do: url
  def absolute_url("/" <> _rest = path), do: @base_url <> path
  def absolute_url(path), do: @base_url <> "/" <> path

  defp named_rows([]), do: []
  defp named_rows(rows) when is_map(rows), do: Map.to_list(rows)
  defp named_rows(_rows), do: []

  defp required_integer_attribute(document, selector, attribute) do
    case optional_attribute(document, selector, attribute) do
      nil ->
        {:error, {:missing_attribute, selector, attribute}}

      value ->
        case Integer.parse(value) do
          {integer, ""} -> {:ok, integer}
          _ -> {:error, {:invalid_integer_attribute, selector, attribute, value}}
        end
    end
  end

  defp required_text(document, selector) do
    case optional_text(document, selector) do
      nil -> {:error, {:missing_text, selector}}
      text -> {:ok, text}
    end
  end

  defp optional_text(document, selector) do
    document
    |> LazyHTML.query(selector)
    |> LazyHTML.text(separator: " ")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
    |> presence(nil)
  end

  defp optional_attribute(document, selector, attribute) do
    document
    |> LazyHTML.query(selector)
    |> LazyHTML.attribute(attribute)
    |> List.first()
    |> presence(nil)
  end

  defp presence(nil, fallback), do: fallback
  defp presence("", fallback), do: fallback
  defp presence(value, _fallback), do: value
end
