defmodule Histoire.TVDB do
  use Ash.Domain,
    otp_app: :histoire,
    extensions: [AshAdmin.Domain, AshAi]

  admin do
    show? true
  end

  tools do
    tool :search_tvdb_titles, Histoire.TVDB.Lookup, :search_titles
    tool :search_web_for_tvdb_title, Histoire.TVDB.Lookup, :search_web
    tool :get_tvdb_series, Histoire.TVDB.Lookup, :get_series
    tool :get_tvdb_movie, Histoire.TVDB.Lookup, :get_movie
    tool :get_tvdb_series_by_slug, Histoire.TVDB.Lookup, :get_series_by_slug
  end

  resources do
    resource Histoire.TVDB.Series
    resource Histoire.TVDB.Movie
    resource Histoire.TVDB.Season
    resource Histoire.TVDB.Artwork
    resource Histoire.TVDB.Lookup
    resource Histoire.TVDB.Sync
  end
end
