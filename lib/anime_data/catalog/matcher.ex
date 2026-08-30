defmodule AnimeData.Catalog.Matcher do
  use Ash.Resource,
    otp_app: :anime_data,
    domain: AnimeData.Catalog

  import AshAi.Actions

  code_interface do
    define :match_tvdb, args: [:name, :synopsis, :release_dates]
  end

  actions do
    action :match_tvdb, AnimeData.Catalog.MatchDecision do
      description "Find the TVDB series corresponding to a SubsPlease anime release."

      argument :name, :string do
        allow_nil? false
        public? true
        description "The title used by SubsPlease"
      end

      argument :synopsis, :string do
        public? true
        description "The SubsPlease synopsis, when available"
      end

      argument :release_dates, {:array, :date} do
        allow_nil? false
        public? true
        description "Observed SubsPlease episode release dates"
      end

      run prompt(
            &AnimeData.AI.Config.model/0,
            prompt: &__MODULE__.prompt/2,
            tools: [:search_tvdb_series, :get_tvdb_series],
            otp_app: :anime_data,
            max_iterations: 8,
            transform_flow: &__MODULE__.configure_flow/2
          )
    end
  end

  def configure_flow(flow, _context) do
    %{flow | req_llm_opts: AnimeData.AI.Config.req_llm_opts()}
  end

  def prompt(input, _context) do
    arguments = input.arguments

    system = """
    You reconcile SubsPlease anime records with TVDB series. Work from evidence, not title similarity alone.

    Use the TVDB search tool yourself. Try translated, romanized, shortened, and alternate titles when useful, then inspect promising series with the detail tool. Compare synopsis, premiere and ending dates, country, language, aliases, and genre. Never select a movie record.

    Return `matched` only when the evidence identifies one TVDB series reliably. Return `needs_review` with the best candidate ID when evidence is plausible but ambiguous. Return `no_match` with a null ID only after reasonable searches find no defensible candidate. Confidence must reflect the evidence, and reasoning must be concise and specific.
    """

    user = """
    SubsPlease title: #{arguments.name}
    Synopsis: #{arguments.synopsis || "not provided"}
    Observed release dates: #{Enum.map_join(arguments.release_dates, ", ", &Date.to_iso8601/1)}
    """

    {system, user}
  end
end
