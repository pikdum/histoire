# histoire

`histoire` mirrors anime metadata into PostgreSQL so clients can query one local API instead of repeatedly hitting upstream sites. Source schemas remain source-shaped; `public` holds reconciliation data that does not belong to one upstream.

## Data flow

1. SubsPlease discovery imports `subsplease.shows`, releases, downloads, and schedule entries.
2. A low-concurrency LLM worker researches unmatched shows through read-only TVDB search/detail tools.
3. Confident results update `public.mappings`; ambiguous results remain `needs_review` for AshAdmin.
4. Accepted TVDB IDs trigger a mirror refresh into `tvdb.series`, seasons, and artworks.

The hot SubsPlease latest poll runs every 30 minutes, schedule polling every six hours, and full discovery daily. Separate polling, source-fetch, matching, and scheduler queues isolate workloads while source-wide rate limiters bound request pressure. TVDB refreshes run daily, and an AshOban trigger continuously recovers pending mappings.

## Development

The devenv provides Elixir 1.20, Erlang/OTP 29, and PostgreSQL 18.

```sh
cp .env.example .env
mix setup
mix phx.server
```

Useful endpoints:

- AshAdmin: `http://localhost:4000/admin`
- Oban Web: `http://localhost:4000/oban`
- health: `http://localhost:4000/health`
- shows: `http://localhost:4000/api/v1/shows`
- show detail: `http://localhost:4000/api/v1/shows/:id`
- schedule: `http://localhost:4000/api/v1/schedule`
- cached Nyaa batch files: `http://localhost:4000/api/v1/downloads/:id/files`

The public API is intentionally a small client read model rather than an exposure of the source
schemas. SubsPlease names and release IDs remain stable for client watch history, while TVDB
contributes synopsis and artwork. BitTorrent info hashes are normalized to lowercase hex; Nyaa
is fetched only for batch file lists and cached in its own source schema.

Run an initial discovery pass from IEx. Pending mappings are scheduled automatically by their AshOban trigger:

```elixir
Histoire.SubsPlease.Sync.discover()
```

`HISTOIRE_MATCHING_MODEL` accepts any ReqLLM model specification. Local development defaults to `openai_codex:gpt-5.6-luna` and reads the native Codex `auth.json` through `CODEX_AUTH_FILE`. Production uses an OpenAI-compatible proxy configured with `HISTOIRE_MATCHING_BASE_URL` and `HISTOIRE_MATCHING_API_KEY`; the API key may be a non-secret placeholder when access is authenticated by the network layer, as it is for the tailnet-only Aperture deployment.

## Nix release

Build the self-contained OTP release for the current system:

```sh
nix build .#histoire
```

Production configuration:

- `PHX_SERVER=true`, `PHX_HOST`, `PORT`, and `SECRET_KEY_BASE`
- either `DATABASE_URL`, or `DATABASE_SOCKET_DIR` plus optional `DATABASE_NAME`/`DATABASE_USER`
- `TVDB_API_KEY`
- `HISTOIRE_MATCHING_MODEL`, `HISTOIRE_MATCHING_BASE_URL`, and `HISTOIRE_MATCHING_API_KEY`
- `ADMIN_USERNAME` and `ADMIN_PASSWORD` to expose `/admin` and `/oban`

Run migrations before starting a new release:

```sh
bin/histoire eval "Histoire.Release.migrate()"
```

The flake exposes both `packages.<system>.default` and `packages.<system>.histoire`, ready to consume as a flake input from the NixOS configuration.
