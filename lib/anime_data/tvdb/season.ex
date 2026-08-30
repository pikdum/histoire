defmodule AnimeData.TVDB.Season do
  use Ash.Resource,
    otp_app: :anime_data,
    domain: AnimeData.TVDB,
    extensions: [AshGraphql.Resource, AshAdmin.Resource],
    data_layer: AshPostgres.DataLayer

  postgres do
    schema "tvdb"
    table "seasons"
    repo AnimeData.Repo

    references do
      reference :series, on_delete: :delete
    end
  end

  graphql do
    type :tvdb_season
  end

  code_interface do
    define :upsert
    define :list, action: :read
  end

  actions do
    defaults [:read, :destroy]

    create :upsert do
      primary? true
      accept [:id, :series_id, :number, :name, :image_url, :overview, :type_id, :type_name, :raw]
      upsert? true

      upsert_fields [
        :series_id,
        :number,
        :name,
        :image_url,
        :overview,
        :type_id,
        :type_name,
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

    attribute :number, :integer, public?: true
    attribute :name, :string, public?: true
    attribute :image_url, :string, public?: true
    attribute :overview, :string, public?: true
    attribute :type_id, :integer, public?: true
    attribute :type_name, :string, public?: true
    attribute :raw, :map
    timestamps()
  end

  relationships do
    belongs_to :series, AnimeData.TVDB.Series do
      attribute_type :integer
      allow_nil? false
      public? true
    end
  end
end
