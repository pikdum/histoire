defmodule AnimeData.Catalog do
  use Ash.Domain, otp_app: :anime_data, extensions: [AshGraphql.Domain]

  graphql do
    authorize? false

    queries do
      get AnimeData.Catalog.Mapping, :mapping, :read
      list AnimeData.Catalog.Mapping, :mappings, :read
    end
  end

  resources do
    resource AnimeData.Catalog.Mapping
    resource AnimeData.Catalog.Matcher
    resource AnimeData.Catalog.MatchSync
  end
end
