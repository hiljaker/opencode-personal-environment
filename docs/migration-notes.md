# Migration notes

Seeded from the supplied OpenCode archive. The repository intentionally excludes:

- `node_modules/` and package metadata that existed only to support local plugin/dependency installation;
- macOS metadata such as `.DS_Store` and `__MACOSX/`;
- `service.json`, because it contained a credential and is machine-local state;
- project/company/domain-specific content from stack skills.

The agent files use OpenCode's native V2 `permissions` frontmatter: an ordered list of `action`/`resource`/`effect` rules that uses the V2 action names (`shell`, `subagent`, `edit`). V2 still accepts the legacy V1 `permission` map keyed by tool and migrates it automatically (`bash` becomes `shell`, `task` becomes `subagent`, `write`/`patch` become `edit`), but the repository keeps the native form so agent behavior does not depend on the compatibility layer.

Agents were consolidated so each one owns a single job: `tutor` merged into `ask`, while `think` and `grill-me` merged into `plan`. External research lives in the `research` subagent.

The skills were rewritten so they describe reusable technology practices rather than any particular application, company, business domain, or internal component library.
