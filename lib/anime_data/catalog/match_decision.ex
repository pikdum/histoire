defmodule AnimeData.Catalog.MatchDecision do
  use Ash.TypedStruct

  typed_struct do
    field :status, :atom,
      allow_nil?: false,
      constraints: [one_of: [:matched, :needs_review, :no_match]],
      description: "Whether a reliable match was found"

    field :tvdb_id, :integer,
      description: "The numeric TVDB series ID, or null when there is no candidate"

    field :confidence, :float,
      allow_nil?: false,
      constraints: [min: 0.0, max: 1.0],
      description: "Confidence from 0.0 to 1.0"

    field :reasoning, :string,
      allow_nil?: false,
      constraints: [min_length: 1],
      description: "A concise explanation citing the evidence used"
  end
end
