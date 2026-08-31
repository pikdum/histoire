defmodule Histoire.Catalog.Matcher do
  use Ash.Resource,
    otp_app: :histoire,
    domain: Histoire.Catalog

  import AshAi.Actions

  code_interface do
    define :match_tvdb, args: [:name, :synopsis, :release_dates]
  end

  actions do
    action :match_tvdb, Histoire.Catalog.MatchDecision do
      description "Find the TVDB title corresponding to a SubsPlease anime release."

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
            &Histoire.AI.Config.model/0,
            prompt: &__MODULE__.prompt/2,
            tools: [
              :search_tvdb_titles,
              :search_web_for_tvdb_title,
              :get_tvdb_series,
              :get_tvdb_movie,
              :get_tvdb_series_by_slug
            ],
            otp_app: :histoire,
            max_iterations: 16,
            transform_flow: &__MODULE__.configure_flow/2
          )
    end
  end

  def configure_flow(flow, _context) do
    %{flow | req_llm_opts: Histoire.AI.Config.req_llm_opts()}
  end

  def prompt(input, _context) do
    arguments = input.arguments

    system = """
    You reconcile SubsPlease anime records with TVDB titles. Work from evidence, not title similarity alone.

    Always start with TVDB search. Do not use web search before trying TVDB. TVDB search is brittle, so actively vary the query: remove punctuation and spaces, replace typographic punctuation, and try translated, romanized, shortened, and alternate titles. Strip suffixes such as S2, Season 2, or Part 2 and search the base title because TVDB commonly stores all seasons under one series.

    For an anime film, prefer the exact TVDB movie record. If no defensible movie record exists, its TVDB series is an acceptable fallback and is better than no match. For episodic releases, prefer the TVDB series. Never select an unrelated movie just because its title is similar.

    Only if TVDB search remains empty or returns only irrelevant records, make a focused web search. Use it to discover alternate titles, official anime information, or a missing thetvdb.com page. Treat web results only as research leads. Validate a discovered series slug with the TVDB series slug tool. Validate a numeric ID from a /movies/ URL with the TVDB movie detail tool. Otherwise use the new evidence to retry TVDB search. Then compare synopsis, release dates, country, language, aliases, and genre.

    Once the evidence is sufficient, stop calling tools and return the structured decision. Do not exhaust the research budget after finding a defensible candidate.

    Return `matched` only when the evidence identifies one TVDB title reliably. Return `needs_review` with the best candidate ID and type when evidence is plausible but ambiguous. Return `no_match` with a null ID and null type only after reasonable searches find no defensible candidate. Confidence must reflect the evidence, and reasoning must be concise and specific.
    """

    user = """
    SubsPlease title: #{arguments.name}
    Synopsis: #{arguments.synopsis || "not provided"}
    Observed release dates: #{Enum.map_join(arguments.release_dates, ", ", &Date.to_iso8601/1)}
    """

    {system, user}
  end
end
