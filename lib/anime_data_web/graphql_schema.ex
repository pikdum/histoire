defmodule AnimeDataWeb.GraphqlSchema do
  use Absinthe.Schema

  use AshGraphql,
    domains: [AnimeData.SubsPlease]

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
