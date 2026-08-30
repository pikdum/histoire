# Anime Data

Anime Data is a local metadata mirror for Haru. It keeps source-owned data in
separate PostgreSQL schemas and exposes the resulting model through Ash,
GraphQL, AshAdmin, and Oban Web.

The first vertical slice mirrors SubsPlease:

| Table | Purpose |
| --- | --- |
| `subsplease.shows` | Upstream show ID, slug, title, synopsis, image, and fetch metadata |
| `subsplease.releases` | Episodes and batches, distinguished by `kind` |
| `subsplease.downloads` | Resolution-specific torrent, magnet, and XDCC links |
| `subsplease.schedule_entries` | The current weekly schedule |
| `public.mappings` | Cross-source IDs; every imported SubsPlease show gets a row |

## Development

The devenv PostgreSQL service provides `anime_data_dev`.

```sh
mix setup
mix phx.server
```

If the current shell predates a `devenv.nix` change, prefix commands with
`devenv shell --`.

Development interfaces:

- GraphQL: <http://localhost:4000/gql/>
- GraphQL playground: <http://localhost:4000/gql/playground>
- AshAdmin: <http://localhost:4000/admin>
- Oban Web: <http://localhost:4000/oban>

The GraphQL schema is also checked in as `schema.graphql`.

## Synchronization

All source calls share a conservative one-request-per-minute gate. The
`subsplease` Oban queue has concurrency one as a second guard. Bulk jobs use
priority 3; latest and schedule polling use priority 0, and can promote a
matching bulk job that is already scheduled.

| Flow | Schedule | Behavior |
| --- | --- | --- |
| Discovery | Daily at 04:00 UTC | Reads `/shows/` and spaces show/release jobs one minute apart |
| Latest | Every 30 minutes | Promotes jobs for the slugs returned by `f=latest` |
| Schedule | Every 6 hours at minute 15 | Mirrors the UTC weekly schedule and queues known shows for five minutes after airtime |

The actions can also be invoked manually:

```sh
mix run -e 'AnimeData.SubsPlease.Sync.discover!()'
mix run -e 'AnimeData.SubsPlease.Sync.latest!()'
mix run -e 'AnimeData.SubsPlease.Sync.schedule!()'
```

Run `mix precommit` before committing. Ash resource changes should be followed
by `mix ash.codegen descriptive_migration_name`, migration review, and
`mix ash.migrate`.

## Next source

TVDB is intentionally the next slice. `public.mappings.tvdb_id` is nullable so
an Ash AI/Jido action can perform LLM-first matching from the richer
SubsPlease record before TVDB data is fetched into its own schema. No title
scoring heuristic is part of the current implementation.
