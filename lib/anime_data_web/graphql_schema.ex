defmodule AnimeDataWeb.GraphqlSchema do
  use Absinthe.Schema

  use AshGraphql,
    domains: [AnimeData.Catalog, AnimeData.SubsPlease, AnimeData.TVDB],
    generate_sdl_file: "schema.graphql",
    auto_generate_sdl_file?: true

  import_types Absinthe.Plug.Types

  query do
  end

  mutation do
    # Custom Absinthe mutations can be placed here
  end

  subscription do
    # Custom Absinthe subscriptions can be placed here
  end
end
