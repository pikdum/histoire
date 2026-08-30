defmodule AnimeData.TVDB.Series do
  use Ash.Resource,
    otp_app: :anime_data,
    domain: AnimeData.TVDB,
    extensions: [AshGraphql.Resource, AshAdmin.Resource],
    data_layer: AshPostgres.DataLayer

  postgres do
    schema "tvdb"
    table "series"
    repo AnimeData.Repo
  end

  graphql do
    type :tvdb_series
  end

  code_interface do
    define :upsert
    define :get_by_id, action: :read, get_by: [:id]
    define :list, action: :read
  end

  actions do
    defaults [:read]

    create :upsert do
      primary? true

      accept [
        :id,
        :name,
        :slug,
        :overview,
        :image_url,
        :first_aired,
        :last_aired,
        :next_aired,
        :year,
        :status_id,
        :status_name,
        :original_country,
        :original_language,
        :average_runtime,
        :score,
        :raw,
        :fetched_at
      ]

      upsert? true

      upsert_fields [
        :name,
        :slug,
        :overview,
        :image_url,
        :first_aired,
        :last_aired,
        :next_aired,
        :year,
        :status_id,
        :status_name,
        :original_country,
        :original_language,
        :average_runtime,
        :score,
        :raw,
        :fetched_at
      ]
    end
  end

  attributes do
    attribute :id, :integer do
      allow_nil? false
      generated? false
      primary_key? true
      public? true
    end

    attribute :name, :string do
      allow_nil? false
      public? true
    end

    attribute :slug, :string, public?: true
    attribute :overview, :string, public?: true
    attribute :image_url, :string, public?: true
    attribute :first_aired, :date, public?: true
    attribute :last_aired, :date, public?: true
    attribute :next_aired, :date, public?: true
    attribute :year, :string, public?: true
    attribute :status_id, :integer, public?: true
    attribute :status_name, :string, public?: true
    attribute :original_country, :string, public?: true
    attribute :original_language, :string, public?: true
    attribute :average_runtime, :integer, public?: true
    attribute :score, :float, public?: true
    attribute :raw, :map

    attribute :fetched_at, :utc_datetime_usec do
      allow_nil? false
      public? true
    end

    timestamps()
  end

  relationships do
    has_many :seasons, AnimeData.TVDB.Season do
      public? true
    end

    has_many :artworks, AnimeData.TVDB.Artwork do
      public? true
    end

    has_one :mapping, AnimeData.Catalog.Mapping do
      destination_attribute :tvdb_id
      public? true
    end
  end
end
