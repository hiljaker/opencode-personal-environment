# Migration notes

Seeded from the supplied OpenCode archive. The repository intentionally excludes:

- `node_modules/` and package metadata that existed only to support local plugin/dependency installation;
- macOS metadata such as `.DS_Store` and `__MACOSX/`;
- `service.json`, because it contained a credential and is machine-local state;
- project/company/domain-specific content from stack skills.

The agent files use OpenCode's `permission` frontmatter (singular, keyed by tool) while preserving their core behavior. An earlier revision used a `permissions` array and a `shell` field, which OpenCode silently ignores; those agents now enforce read-only intent through `permission.edit` and `permission.bash`.

Agents were consolidated so each one owns a single job: `tutor` merged into `ask`, while `think` and `grill-me` merged into `plan`. External research lives in the `research` subagent.

The skills were rewritten so they describe reusable technology practices rather than any particular application, company, business domain, or internal component library.
