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

Run an initial discovery pass from IEx. Pending mappings are scheduled automatically by their AshOban trigger:

```elixir
Histoire.SubsPlease.Sync.discover()
```

`HISTOIRE_MATCHING_MODEL` accepts any ReqLLM model specification. The default is `openai_codex:gpt-5.6-luna`. Development can read a native Codex `auth.json` through `CODEX_AUTH_FILE`. For deployment, use `REQ_LLM_OAUTH_FILE` pointing at a writable secret/state file with an `openai-codex` entry; ReqLLM may refresh it in place, so do not put it in the immutable Nix store.

## Nix release

Build the self-contained OTP release for the current system:

```sh
nix build .#histoire
```

Production configuration:

- `PHX_SERVER=true`, `PHX_HOST`, `PORT`, and `SECRET_KEY_BASE`
- either `DATABASE_URL`, or `DATABASE_SOCKET_DIR` plus optional `DATABASE_NAME`/`DATABASE_USER`
- `TVDB_API_KEY`
- `HISTOIRE_MATCHING_MODEL` and its provider credentials
- `ADMIN_USERNAME` and `ADMIN_PASSWORD` to expose `/admin` and `/oban`

Run migrations before starting a new release:

```sh
bin/histoire eval "Histoire.Release.migrate()"
```

The flake exposes both `packages.<system>.default` and `packages.<system>.histoire`, ready to consume as a flake input from the NixOS configuration.
