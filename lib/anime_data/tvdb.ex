defmodule AnimeData.TVDB do
  use Ash.Domain, otp_app: :anime_data, extensions: [AshGraphql.Domain, AshAi]

  graphql do
    authorize? false

    queries do
      get AnimeData.TVDB.Series, :tvdb_series, :read
      list AnimeData.TVDB.Series, :tvdb_series_list, :read
      list AnimeData.TVDB.Season, :tvdb_seasons, :read
      list AnimeData.TVDB.Artwork, :tvdb_artworks, :read
    end
  end

  tools do
    tool :search_tvdb_series, AnimeData.TVDB.Lookup, :search_series
    tool :get_tvdb_series, AnimeData.TVDB.Lookup, :get_series
  end

  resources do
    resource AnimeData.TVDB.Series
    resource AnimeData.TVDB.Season
    resource AnimeData.TVDB.Artwork
    resource AnimeData.TVDB.Lookup
    resource AnimeData.TVDB.Sync
  end
end
