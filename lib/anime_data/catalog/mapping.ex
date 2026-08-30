defmodule AnimeData.Catalog.Mapping do
  use Ash.Resource,
    otp_app: :anime_data,
    domain: AnimeData.Catalog,
    extensions: [AshAdmin.Resource],
    data_layer: AshPostgres.DataLayer

  postgres do
    schema "public"
    table "mappings"
    repo AnimeData.Repo
  end

  code_interface do
    define :upsert_subsplease
    define :get_by_subsplease_id, action: :read, get_by: [:subsplease_id]
    define :without_tvdb, action: :read
  end

  actions do
    defaults [:read]

    create :upsert_subsplease do
      primary? true
      accept [:subsplease_id]
      upsert? true
      upsert_identity :unique_subsplease_id
      upsert_fields []
    end

    update :set_tvdb do
      require_atomic? false
      accept [:tvdb_id]
    end

    read :without_tvdb do
      filter expr(is_nil(tvdb_id))
    end
  end

  attributes do
    uuid_v7_primary_key :id

    attribute :subsplease_id, :integer do
      allow_nil? false
      public? true
    end

    attribute :tvdb_id, :integer do
      public? true
    end

    timestamps()
  end

  identities do
    identity :unique_subsplease_id, [:subsplease_id]
    identity :unique_tvdb_id, [:tvdb_id], nils_distinct?: true
  end
end
