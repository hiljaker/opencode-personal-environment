# Migration notes

Seeded from the supplied OpenCode archive. The repository intentionally excludes:

- `node_modules/` and package metadata that existed only to support local plugin/dependency installation;
- macOS metadata such as `.DS_Store` and `__MACOSX/`;
- `service.json`, because it contained a credential and is machine-local state;
- project/company/domain-specific content from stack skills.

The agent files were normalized to OpenCode V2 frontmatter (`permissions`, `shell`) while preserving their core behavior.

The skills were rewritten so they describe reusable technology practices rather than any particular application, company, business domain, or internal component library.
