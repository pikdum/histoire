defmodule AnimeData.Catalog.Mapping do
  use Ash.Resource,
    otp_app: :anime_data,
    domain: AnimeData.Catalog,
    extensions: [AshGraphql.Resource, AshAdmin.Resource, AshOban],
    data_layer: AshPostgres.DataLayer

  postgres do
    schema "public"
    table "mappings"
    repo AnimeData.Repo

    references do
      reference :subsplease_show, ignore?: true
      reference :tvdb_series, ignore?: true
      reference :tvdb_movie, ignore?: true
    end

    custom_indexes do
      index [:tvdb_id]
    end
  end

  oban do
    shared_context [:job]

    triggers do
      trigger :match_tvdb do
        action :run_tvdb_match
        on_error :record_match_failure
        where expr(status == :pending and is_nil(tvdb_id))
        scheduler_cron "* * * * *"
        queue :tvdb_match
        scheduler_queue :schedulers
        worker_priority 2
        scheduler_priority 1
        max_attempts 3
        lock_for_update? false
        tags ["catalog", "tvdb-match"]
        worker_module_name AnimeData.Catalog.Workers.MatchTVDB
        scheduler_module_name AnimeData.Catalog.Schedulers.MatchTVDB
      end
    end
  end

  graphql do
    type :mapping
  end

  code_interface do
    define :upsert_subsplease
    define :get_by_id, action: :read, get_by: [:id]
    define :get_by_subsplease_id, action: :read, get_by: [:subsplease_id]
    define :without_tvdb, action: :read
    define :record_result
    define :run_tvdb_match
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
      accept [:tvdb_id, :tvdb_type]
      validate present([:tvdb_id, :tvdb_type])
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

    update :run_tvdb_match do
      transaction? false
      require_atomic? false
      accept []
      change AnimeData.Catalog.Changes.RunTVDBMatch
    end

    update :record_result do
      require_atomic? false

      accept [
        :tvdb_id,
        :tvdb_type,
        :candidate_tvdb_id,
        :candidate_tvdb_type,
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

    update :record_match_failure do
      require_atomic? false
      accept []

      argument :error, :term do
        allow_nil? false
      end

      change AnimeData.Catalog.Changes.RecordMatchFailure
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

    attribute :tvdb_type, :atom do
      constraints one_of: [:series, :movie]
      public? true
    end

    attribute :candidate_tvdb_id, :integer do
      public? true
    end

    attribute :candidate_tvdb_type, :atom do
      constraints one_of: [:series, :movie]
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

    attribute :last_attempted_at, :utc_datetime_usec

    attribute :last_error, :string

    attribute :attempts, :integer do
      allow_nil? false
      default 0
      constraints min: 0
    end

    timestamps()
  end

  relationships do
    belongs_to :subsplease_show, AnimeData.SubsPlease.Show do
      source_attribute :subsplease_id
      destination_attribute :id
      define_attribute? false
      public? true
    end

    belongs_to :tvdb_series, AnimeData.TVDB.Series do
      source_attribute :tvdb_id
      destination_attribute :id
      define_attribute? false
      filter expr(parent(tvdb_type) == :series)
      public? true
    end

    belongs_to :tvdb_movie, AnimeData.TVDB.Movie do
      source_attribute :tvdb_id
      destination_attribute :id
      define_attribute? false
      filter expr(parent(tvdb_type) == :movie)
      public? true
    end
  end

  identities do
    identity :unique_subsplease_id, [:subsplease_id]
  end
end
