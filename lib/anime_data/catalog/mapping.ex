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
    define :get_by_id, action: :read, get_by: [:id]
    define :get_by_subsplease_id, action: :read, get_by: [:subsplease_id]
    define :without_tvdb, action: :read
    define :record_result
    define :record_failure
    define :set_tvdb
    define :accept_candidate
    define :retry_match
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
      change AnimeData.Catalog.Changes.FinalizeMatch
    end

    update :accept_candidate do
      require_atomic? false
      accept []
      change AnimeData.Catalog.Changes.AcceptCandidate
    end

    update :retry_match do
      require_atomic? false
      accept []
      change AnimeData.Catalog.Changes.RetryMatch
    end

    update :record_result do
      require_atomic? false

      accept [
        :tvdb_id,
        :candidate_tvdb_id,
        :status,
        :match_confidence,
        :match_reasoning,
        :match_method,
        :matched_at,
        :last_attempted_at,
        :last_error,
        :attempts
      ]
    end

    update :record_failure do
      require_atomic? false
      accept [:last_attempted_at, :last_error, :attempts]
      change set_attribute(:status, :failed)
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

    attribute :candidate_tvdb_id, :integer do
      public? true
    end

    attribute :status, :atom do
      allow_nil? false
      default :pending
      constraints one_of: [:pending, :matched, :needs_review, :no_match, :failed]
      public? true
    end

    attribute :match_confidence, :float do
      constraints min: 0.0, max: 1.0
      public? true
    end

    attribute :match_reasoning, :string do
      public? true
    end

    attribute :match_method, :atom do
      constraints one_of: [:llm, :manual]
      public? true
    end

    attribute :matched_at, :utc_datetime_usec do
      public? true
    end

    attribute :last_attempted_at, :utc_datetime_usec do
      public? true
    end

    attribute :last_error, :string do
      public? true
    end

    attribute :attempts, :integer do
      allow_nil? false
      default 0
      constraints min: 0
      public? true
    end

    timestamps()
  end

  identities do
    identity :unique_subsplease_id, [:subsplease_id]
    identity :unique_tvdb_id, [:tvdb_id], nils_distinct?: true
  end
end
