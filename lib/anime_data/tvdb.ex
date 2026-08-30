defmodule AnimeData.TVDB do
  use Ash.Domain, otp_app: :anime_data, extensions: [AshGraphql.Domain]

  graphql do
    authorize? false

    queries do
      get AnimeData.TVDB.Series, :tvdb_series, :read
      list AnimeData.TVDB.Series, :tvdb_series_list, :read
      list AnimeData.TVDB.Season, :tvdb_seasons, :read
      list AnimeData.TVDB.Artwork, :tvdb_artworks, :read
    end
  end

  resources do
    resource AnimeData.TVDB.Series
    resource AnimeData.TVDB.Season
    resource AnimeData.TVDB.Artwork
    resource AnimeData.TVDB.Sync
  end
end
