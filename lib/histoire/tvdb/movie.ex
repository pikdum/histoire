defmodule Histoire.TVDB.Movie do
  use Ash.Resource,
    otp_app: :histoire,
    domain: Histoire.TVDB,
    extensions: [AshAdmin.Resource],
    data_layer: AshPostgres.DataLayer

  postgres do
    schema "tvdb"
    table "movies"
    repo Histoire.Repo
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
        :first_released,
        :year,
        :status_id,
        :status_name,
        :original_country,
        :original_language,
        :runtime,
        :score,
        :raw,
        :fetched_at
      ]

      upsert? true
      upsert_fields {:replace, [:id, :inserted_at]}
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
    attribute :first_released, :date, public?: true
    attribute :year, :string, public?: true
    attribute :status_id, :integer, public?: true
    attribute :status_name, :string, public?: true
    attribute :original_country, :string, public?: true
    attribute :original_language, :string, public?: true
    attribute :runtime, :integer, public?: true
    attribute :score, :float, public?: true
    attribute :raw, :map

    attribute :fetched_at, :utc_datetime_usec do
      allow_nil? false
      public? true
    end

    timestamps()
  end

  relationships do
    has_many :mappings, Histoire.Catalog.Mapping do
      destination_attribute :tvdb_id
      filter expr(tvdb_type == :movie)
      public? true
    end
  end
end
