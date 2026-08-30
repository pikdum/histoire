defmodule AnimeData.Catalog do
  use Ash.Domain, otp_app: :anime_data

  resources do
    resource AnimeData.Catalog.Mapping
  end
end
