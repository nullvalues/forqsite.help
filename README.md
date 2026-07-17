# forqsite.help

Administrator documentation for [forqsite](https://github.com/nullvalues/forqsite) —
the self-hosted, multi-tenant website builder.

**Live site:** https://forqsite.help

## Why this repo exists

Every other forqsite property (including forqsite.com) is dogfooded as a tenant on a
forqsite installation. **This site deliberately is not.** It is plain, self-contained
HTML with zero runtime dependencies: no server, no database, no build step. The docs
stay available even when a forqsite instance is down.

## Contents

| File | What it is |
|---|---|
| `index.html` | The docs site. Builders (dev setup, daily runbook), self-hosters (non-docker production install, systemd supervision, operations, backup & recovery, provider lifecycle), and reference (searchable env-var table, architecture/topology, dev→prod pipeline map). |
| `gap-handoff.html` | Dev → prod gap analysis formatted as Claude Code work items (GAP-002…011, 10 items) with evidence, proposed approach, and acceptance criteria. Linked from the docs sidebar. |

Each file is a single fully-inlined HTML document (fonts, styles, and scripts embedded).
They work offline, from `file://`, or behind any static file server.

## Hosting

Anything that serves static files works as-is:

```
# Caddy
forqsite.help {
    root * /srv/forqsite.help
    file_server
}
```

GitHub Pages, nginx, or `python3 -m http.server` are equally fine. No headers,
rewrites, or MIME tricks required.

## Updating

These files are **generated artifacts** — do not hand-edit them (they are compiled,
single-file bundles). The source of truth is the "Forqsite documentation and DevOps
gaps" design session; edits are made there and re-exported, then committed here.

Content is grounded in `nullvalues/forqsite@main`. When the repo changes in ways that
affect operators (config keys, scripts, install procedure, provider loading), the docs
should be re-synced — the gap-handoff items in particular are point-in-time findings
and should be pruned as Claude Code lands them.

## Scope

Curated essentials for builders and self-hosters. Deep reference remains in the main
repo: `docs/architecture.md`, `docs/configuration.md`, `docs/operator-runbook.md`.
