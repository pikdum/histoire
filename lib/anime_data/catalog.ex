defmodule AnimeData.Catalog do
  use Ash.Domain, otp_app: :anime_data

  resources do
    resource AnimeData.Catalog.Mapping
    resource AnimeData.Catalog.Matcher
    resource AnimeData.Catalog.MatchSync
  end
end
