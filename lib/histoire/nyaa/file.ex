defmodule Histoire.Nyaa.File do
  use Ash.Resource,
    otp_app: :histoire,
    domain: Histoire.Nyaa,
    extensions: [AshAdmin.Resource],
    data_layer: AshPostgres.DataLayer

  postgres do
    schema "nyaa"
    table "files"
    repo Histoire.Repo

    references do
      reference :torrent, on_delete: :delete
    end

    custom_indexes do
      index [:torrent_id]
    end
  end

  code_interface do
    define :upsert
  end

  actions do
    defaults [:read]

    create :upsert do
      primary? true
      accept [:torrent_id, :path, :size]
      upsert? true
      upsert_identity :torrent_path
      upsert_fields [:size]
    end
  end

  attributes do
    uuid_v7_primary_key :id

    attribute :path, :string do
      allow_nil? false
      public? true
    end

    attribute :size, :string do
      public? true
    end

    timestamps()
  end

  relationships do
    belongs_to :torrent, Histoire.Nyaa.Torrent do
      attribute_type :integer
      allow_nil? false
      public? true
    end
  end

  identities do
    identity :torrent_path, [:torrent_id, :path]
  end
end
