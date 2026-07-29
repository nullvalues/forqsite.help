---
id: "001"
name: forqsite.help — Initial development
status: active
---

## Strategic intent

Keep forqsite's administrator documentation available and accurate as a zero-dependency
static site that survives a forqsite outage — and track the dev→prod gap backlog
(`gap-handoff.html`) as it gets closed upstream in `nullvalues/forqsite`.

## Rails

| Rail | Primary domain |
|------|----------------|
| CONTENT | `index.html` docs content — builder/self-hoster/reference sections, env-var table, architecture maps |
| INFRA | Hosting, publishing, the generated-artifact re-export workflow, `gap-handoff.html` backlog upkeep |
| TEST | Verifying generated HTML renders correctly (offline/`file://`, static server), link and content accuracy checks |
| API | _(fill in primary domain)_ |
| UI | _(fill in primary domain)_ |
| DB | _(fill in primary domain)_ |
| AUTH | _(fill in primary domain)_ |

## Phases

| Phase | Title | Status |
|-------|-------|--------|
| 1 | Bootstrap pairmode methodology | planned |
| 2 | Refresh docs against forqsite drift | planned |
| 3 | Drift re-sweep vs forqsite source (pairmode 0.3.0 proving cycle) | planned |
