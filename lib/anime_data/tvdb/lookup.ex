defmodule AnimeData.TVDB.Lookup do
  use Ash.Resource,
    otp_app: :anime_data,
    domain: AnimeData.TVDB

  code_interface do
    define :search_series, args: [:query]
    define :search_web, args: [:query]
    define :get_series, args: [:tvdb_id]
    define :get_series_by_slug, args: [:slug]
  end

  actions do
    action :search_series, {:array, :map} do
      description "Search TVDB for series candidates. Try alternate and translated titles as needed."

      argument :query, :string do
        allow_nil? false
        public? true
        description "A title or alternate title to search for"
      end

      run fn input, _context ->
        :ok = AnimeData.TVDB.WebSearch.mark_tvdb_searched()

        with {:ok, rows} <- AnimeData.TVDB.Client.search(input.arguments.query) do
          {:ok,
           rows
           |> Enum.filter(&(&1["type"] == "series"))
           |> Enum.map(&search_result/1)}
        end
      end
    end

    action :get_series, :map do
      description "Fetch detailed TVDB evidence for one numeric series ID."

      argument :tvdb_id, :integer do
        allow_nil? false
        public? true
        description "The numeric TVDB series ID from search results"
      end

      run fn input, _context ->
        with {:ok, row} <- AnimeData.TVDB.Client.fetch_series(input.arguments.tvdb_id) do
          {:ok, series_result(row)}
        end
      end
    end

    action :search_web, {:array, :map} do
      description "Search the web for additional evidence when TVDB's own search is incomplete."

      argument :query, :string do
        allow_nil? false
        public? true

        description "A focused web query for alternate titles, official information, or TVDB pages"
      end

      run fn input, _context ->
        AnimeData.TVDB.WebSearch.search(input.arguments.query)
      end
    end

    action :get_series_by_slug, :map do
      description "Resolve and validate a TVDB series slug discovered from a thetvdb.com URL."

      argument :slug, :string do
        allow_nil? false
        public? true
        description "The slug from a URL such as https://thetvdb.com/series/example-slug"
      end

      run fn input, _context ->
        slug = input.arguments.slug

        if Regex.match?(~r/\A[a-z0-9][a-z0-9-]*\z/, slug) do
          with {:ok, %{"id" => id}} <- AnimeData.TVDB.Client.fetch_series_by_slug(slug),
               {:ok, row} <- AnimeData.TVDB.Client.fetch_series(id) do
            {:ok, series_result(row)}
          end
        else
          {:error, {:invalid_tvdb_slug, slug}}
        end
      end
    end
  end

  defp search_result(row) do
    Map.take(row, [
      "tvdb_id",
      "name",
      "slug",
      "aliases",
      "year",
      "first_air_time",
      "primary_language",
      "country",
      "overview",
      "image_url"
    ])
  end

  defp series_result(row) do
    status = row["status"] || %{}

    %{
      "tvdb_id" => row["id"],
      "name" => row["name"],
      "aliases" => row["aliases"],
      "slug" => row["slug"],
      "year" => row["year"],
      "first_aired" => row["firstAired"],
      "last_aired" => row["lastAired"],
      "next_aired" => row["nextAired"],
      "overview" => row["overview"],
      "original_country" => row["originalCountry"],
      "original_language" => row["originalLanguage"],
      "status" => status["name"],
      "genres" => Enum.map(row["genres"] || [], & &1["name"]),
      "remote_ids" => row["remoteIds"]
    }
  end
end
