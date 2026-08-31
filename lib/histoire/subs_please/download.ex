defmodule Histoire.SubsPlease.Download do
  use Ash.Resource,
    otp_app: :histoire,
    domain: Histoire.SubsPlease,
    extensions: [AshAdmin.Resource],
    data_layer: AshPostgres.DataLayer

  postgres do
    schema "subsplease"
    table "downloads"
    repo Histoire.Repo

    references do
      reference :release, on_delete: :delete
    end
  end

  code_interface do
    define :upsert
    define :destroy
  end

  actions do
    defaults [:read, :destroy]

    create :upsert do
      primary? true
      accept [:release_id, :resolution, :torrent_url, :magnet_uri, :xdcc, :raw]
      upsert? true
      upsert_identity :release_resolution
      upsert_fields [:torrent_url, :magnet_uri, :xdcc, :raw]
    end
  end

  attributes do
    uuid_v7_primary_key :id

    attribute :resolution, :string do
      allow_nil? false
      public? true
    end

    attribute :torrent_url, :string do
      public? true
    end

    attribute :magnet_uri, :string do
      public? true
    end

    attribute :xdcc, :string do
      public? true
    end

    attribute :raw, :map

    timestamps()
  end

  relationships do
    belongs_to :release, Histoire.SubsPlease.Release do
      allow_nil? false
      public? true
    end
  end

  identities do
    identity :release_resolution, [:release_id, :resolution]
  end
end
