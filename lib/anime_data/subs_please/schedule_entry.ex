defmodule AnimeData.SubsPlease.ScheduleEntry do
  use Ash.Resource,
    otp_app: :anime_data,
    domain: AnimeData.SubsPlease,
    extensions: [AshGraphql.Resource, AshAdmin.Resource],
    data_layer: AshPostgres.DataLayer

  postgres do
    schema "subsplease"
    table "schedule_entries"
    repo AnimeData.Repo

    references do
      reference :show, on_delete: :nilify
    end

    custom_indexes do
      index [:show_id]
    end
  end

  graphql do
    type :schedule_entry
  end

  code_interface do
    define :upsert
    define :list, action: :read
    define :destroy
  end

  actions do
    defaults [:read, :destroy]

    create :upsert do
      primary? true

      accept [
        :show_id,
        :slug,
        :title,
        :weekday,
        :scheduled_time,
        :image_url,
        :aired,
        :observed_at,
        :raw
      ]

      upsert? true
      upsert_identity :slug_weekday

      upsert_fields [
        :show_id,
        :title,
        :scheduled_time,
        :image_url,
        :aired,
        :observed_at,
        :raw
      ]
    end
  end

  attributes do
    uuid_v7_primary_key :id

    attribute :slug, :string do
      allow_nil? false
      public? true
    end

    attribute :title, :string do
      allow_nil? false
      public? true
    end

    attribute :weekday, :string do
      allow_nil? false
      public? true
    end

    attribute :scheduled_time, :time do
      allow_nil? false
      public? true
    end

    attribute :image_url, :string do
      public? true
    end

    attribute :aired, :boolean do
      default false
      allow_nil? false
      public? true
    end

    attribute :observed_at, :utc_datetime_usec do
      allow_nil? false
      public? true
    end

    attribute :raw, :map

    timestamps()
  end

  relationships do
    belongs_to :show, AnimeData.SubsPlease.Show do
      attribute_type :integer
      public? true
    end
  end

  identities do
    identity :slug_weekday, [:slug, :weekday]
  end
end
