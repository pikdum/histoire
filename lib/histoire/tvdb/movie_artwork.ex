defmodule Histoire.TVDB.MovieArtwork do
  use Ash.Resource,
    otp_app: :histoire,
    domain: Histoire.TVDB,
    extensions: [AshAdmin.Resource],
    data_layer: AshPostgres.DataLayer

  postgres do
    schema "tvdb"
    table "movie_artworks"
    repo Histoire.Repo

    references do
      reference :movie, on_delete: :delete
    end

    custom_indexes do
      index [:movie_id]
    end
  end

  code_interface do
    define :upsert
    define :list, action: :read
    define :for_movie, args: [:movie_id]
  end

  actions do
    defaults [:read, :destroy]

    read :for_movie do
      argument :movie_id, :integer, allow_nil?: false
      filter expr(movie_id == ^arg(:movie_id))
    end

    create :upsert do
      primary? true

      accept [
        :id,
        :movie_id,
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
        :movie_id,
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
    belongs_to :movie, Histoire.TVDB.Movie do
      attribute_type :integer
      allow_nil? false
      public? true
    end
  end
end
