defmodule AnimeData.SubsPlease.Show do
  use Ash.Resource,
    otp_app: :anime_data,
    domain: AnimeData.SubsPlease,
    extensions: [AshGraphql.Resource, AshAdmin.Resource],
    data_layer: AshPostgres.DataLayer

  postgres do
    schema "subsplease"
    table "shows"
    repo AnimeData.Repo
  end

  graphql do
    type :show
  end

  code_interface do
    define :upsert
    define :get_by_id, action: :read, get_by: [:id]
    define :get_by_slug, action: :read, get_by: [:slug]
    define :list, action: :read
  end

  actions do
    defaults [:read]

    create :upsert do
      primary? true
      accept [:id, :slug, :name, :synopsis, :image_url, :raw, :fetched_at]
      upsert? true
      upsert_fields [:slug, :name, :synopsis, :image_url, :raw, :fetched_at]
    end
  end

  attributes do
    attribute :id, :integer do
      allow_nil? false
      generated? false
      primary_key? true
      public? true
    end

    attribute :slug, :string do
      allow_nil? false
      public? true
    end

    attribute :name, :string do
      allow_nil? false
      public? true
    end

    attribute :synopsis, :string do
      public? true
    end

    attribute :image_url, :string do
      public? true
    end

    attribute :raw, :map

    attribute :fetched_at, :utc_datetime_usec do
      allow_nil? false
      public? true
    end

    timestamps()
  end

  relationships do
    has_many :releases, AnimeData.SubsPlease.Release do
      public? true
    end
  end

  identities do
    identity :unique_slug, [:slug]
  end
end
