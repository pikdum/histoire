defmodule Histoire.SubsPlease.Release do
  use Ash.Resource,
    otp_app: :histoire,
    domain: Histoire.SubsPlease,
    extensions: [AshAdmin.Resource],
    data_layer: AshPostgres.DataLayer

  postgres do
    schema "subsplease"
    table "releases"
    repo Histoire.Repo

    references do
      reference :show, on_delete: :delete
    end
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
        :show_id,
        :kind,
        :name,
        :episode,
        :source_date,
        :released_at,
        :raw_time,
        :raw
      ]

      upsert? true
      upsert_identity :show_kind_name
      upsert_fields [:episode, :source_date, :released_at, :raw_time, :raw]
    end
  end

  attributes do
    uuid_v7_primary_key :id

    attribute :kind, :atom do
      allow_nil? false
      constraints one_of: [:episode, :batch]
      public? true
    end

    attribute :name, :string do
      allow_nil? false
      public? true
    end

    attribute :episode, :string do
      allow_nil? false
      public? true
    end

    attribute :source_date, :date do
      public? true
    end

    attribute :released_at, :utc_datetime_usec do
      public? true
    end

    attribute :raw_time, :string do
      public? true
    end

    attribute :raw, :map

    timestamps()
  end

  relationships do
    belongs_to :show, Histoire.SubsPlease.Show do
      attribute_type :integer
      allow_nil? false
      public? true
    end

    has_many :downloads, Histoire.SubsPlease.Download do
      public? true
    end
  end

  identities do
    identity :show_kind_name, [:show_id, :kind, :name]
  end
end
