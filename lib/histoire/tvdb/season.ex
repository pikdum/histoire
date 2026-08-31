defmodule Histoire.TVDB.Season do
  use Ash.Resource,
    otp_app: :histoire,
    domain: Histoire.TVDB,
    extensions: [AshAdmin.Resource],
    data_layer: AshPostgres.DataLayer

  postgres do
    schema "tvdb"
    table "seasons"
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
    belongs_to :series, Histoire.TVDB.Series do
      attribute_type :integer
      allow_nil? false
      public? true
    end
  end
end
