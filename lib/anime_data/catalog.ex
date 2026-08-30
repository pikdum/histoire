defmodule AnimeData.Catalog do
  use Ash.Domain, otp_app: :anime_data, extensions: [AshGraphql.Domain, AshAdmin.Domain]

  admin do
    show? true
  end

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
  end
end
