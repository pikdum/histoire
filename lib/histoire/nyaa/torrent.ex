defmodule Histoire.Nyaa.Torrent do
  use Ash.Resource,
    otp_app: :histoire,
    domain: Histoire.Nyaa,
    extensions: [AshAdmin.Resource],
    data_layer: AshPostgres.DataLayer

  postgres do
    schema "nyaa"
    table "torrents"
    repo Histoire.Repo
  end

  code_interface do
    define :upsert
    define :get_by_id, action: :read, get_by: [:id], not_found_error?: false
  end

  actions do
    defaults [:read]

    create :upsert do
      primary? true
      accept [:id, :title, :page_url, :magnet_uri, :fetched_at]
      upsert? true
      upsert_fields [:title, :page_url, :magnet_uri, :fetched_at]
    end
  end

  attributes do
    attribute :id, :integer do
      allow_nil? false
      generated? false
      primary_key? true
      public? true
    end

    attribute :title, :string do
      allow_nil? false
      public? true
    end

    attribute :page_url, :string do
      allow_nil? false
      public? true
    end

    attribute :magnet_uri, :string do
      allow_nil? false
      public? true
    end

    attribute :fetched_at, :utc_datetime_usec do
      allow_nil? false
      public? true
    end

    timestamps()
  end

  relationships do
    has_many :files, Histoire.Nyaa.File do
      public? true
    end
  end
end
