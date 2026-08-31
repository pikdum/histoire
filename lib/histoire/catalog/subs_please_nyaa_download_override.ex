defmodule Histoire.Catalog.SubsPleaseNyaaDownloadOverride do
  use Ash.Resource,
    otp_app: :histoire,
    domain: Histoire.Catalog,
    extensions: [AshAdmin.Resource],
    data_layer: AshPostgres.DataLayer

  postgres do
    schema "catalog"
    table "subsplease_nyaa_download_overrides"
    repo Histoire.Repo

    references do
      reference :subsplease_download, on_delete: :delete
      reference :nyaa_torrent
    end

    custom_indexes do
      index [:nyaa_id]
    end
  end

  code_interface do
    define :put

    define :get_by_subsplease_download_id,
      action: :read,
      get_by: [:subsplease_download_id],
      not_found_error?: false

    define :destroy
  end

  actions do
    defaults [:read, :destroy]

    create :put do
      primary? true
      accept [:subsplease_download_id, :nyaa_id, :note]
      upsert? true
      upsert_fields [:nyaa_id, :note]
      change Histoire.Catalog.Changes.ValidateNyaaTorrent
    end
  end

  attributes do
    attribute :subsplease_download_id, :uuid do
      allow_nil? false
      primary_key? true
      public? true
    end

    attribute :nyaa_id, :integer do
      allow_nil? false
      constraints min: 1
      public? true
    end

    attribute :note, :string

    timestamps()
  end

  relationships do
    belongs_to :subsplease_download, Histoire.SubsPlease.Download do
      source_attribute :subsplease_download_id
      destination_attribute :id
      define_attribute? false
      public? true
    end

    belongs_to :nyaa_torrent, Histoire.Nyaa.Torrent do
      source_attribute :nyaa_id
      destination_attribute :id
      define_attribute? false
      public? true
    end
  end
end
