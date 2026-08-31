defmodule Histoire.TVDB.Artwork do
  use Ash.Resource,
    otp_app: :histoire,
    domain: Histoire.TVDB,
    extensions: [AshAdmin.Resource],
    data_layer: AshPostgres.DataLayer

  postgres do
    schema "tvdb"
    table "artworks"
    repo Histoire.Repo

    references do
      reference :series, on_delete: :delete
    end

    custom_indexes do
      index [:series_id]
    end
  end

  code_interface do
    define :upsert
    define :list, action: :read
    define :for_series, args: [:series_id]
  end

  actions do
    defaults [:read, :destroy]

    read :for_series do
      argument :series_id, :integer, allow_nil?: false
      filter expr(series_id == ^arg(:series_id))
    end

    create :upsert do
      primary? true

      accept [
        :id,
        :series_id,
        :artwork_type,
        :language,
        :image_url,
        :thumbnail_url,
        :includes_text,
        :score,
        :width,
        :height,
        :raw
      ]

      upsert? true

      upsert_fields [
        :series_id,
        :artwork_type,
        :language,
        :image_url,
        :thumbnail_url,
        :includes_text,
        :score,
        :width,
        :height,
        :raw
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

    attribute :artwork_type, :integer, public?: true
    attribute :language, :string, public?: true

    attribute :image_url, :string do
      allow_nil? false
      public? true
    end

    attribute :thumbnail_url, :string, public?: true
    attribute :includes_text, :boolean, public?: true
    attribute :score, :float, public?: true
    attribute :width, :integer, public?: true
    attribute :height, :integer, public?: true
    attribute :raw, :map
    timestamps()
  end

  relationships do
    belongs_to :series, Histoire.TVDB.Series do
      attribute_type :integer
      allow_nil? false
      public? true
    end
  end
end
