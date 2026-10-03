# Personal OpenCode Environment

A portable, Git-installable personal OpenCode environment. The repository is the source of truth for the parts of OpenCode that should be reproducible across machines: global configuration, agents, commands, skills, and optional extensions.

## One-command install

Once this repository is public on GitHub, a new macOS/Linux device can install the environment without cloning it first:

```bash
curl -fsSL https://raw.githubusercontent.com/<OWNER>/personal-opencode-environment/main/install.sh | bash
```

Before pushing the repository, replace `YOUR_GITHUB_USERNAME/personal-opencode-environment` in the root `install.sh` with the real GitHub `owner/repository`. The remote bootstrap then downloads the selected branch/tag archive and runs the local installer from a temporary directory.

For a pinned release instead of `main`:

```bash
curl -fsSL https://raw.githubusercontent.com/<OWNER>/personal-opencode-environment/v1.0.0/install.sh | bash
```

The repository itself remains the source of truth; no permanent clone is required just to install or update the environment.

## Local install

```bash
./install.sh
```

The installer targets OpenCode's global config directory. On macOS/Linux this follows `XDG_CONFIG_HOME` when set, otherwise `~/.config/opencode`. The repository currently manages `opencode.jsonc`, `cli.json`, `AGENTS.md`, `agents/`, `commands/`, `skills/`, `plugins/`, `tools/`, and `themes/`.

## What is included

- Global `opencode.jsonc`
- Global `cli.json`
- Global `AGENTS.md`
- Reusable agents
- Reusable slash commands
- General stack skills for React/TypeScript, NestJS, Go/Gin/GORM, and Flutter/Riverpod
- Optional directories for plugins, tools, and themes
- Backup, update, uninstall, and validation scripts

All skills are intentionally project-agnostic. They should describe engineering practices, framework conventions, architecture patterns, and trade-offs, not any specific company, product, repository, business domain, API, database schema, or internal component.

## Update

Re-run the same command:

```bash
curl -fsSL https://raw.githubusercontent.com/<OWNER>/personal-opencode-environment/main/install.sh | bash
```

The installer backs up currently managed files before replacing them. It also removes files that this repository previously managed but no longer ships, while leaving unrelated files in the OpenCode config directory untouched.

## Uninstall

For a cloned repository:

```bash
./uninstall.sh
```

Uninstall only removes files previously installed by this environment. Unmanaged files are left alone.

## Validate

```bash
./doctor.sh
```

The doctor checks repository structure, skill frontmatter, forbidden local-context references, and the target config directory.

## Authentication and machine state

Credentials are intentionally not part of the repository. On a new device, authenticate providers locally through OpenCode, for example with `/connect`. Provider credentials and runtime state remain machine-local.

The environment installer does **not** install the OpenCode binary itself. OpenCode's official current v2 installer is separate:

```bash
curl -fsSL https://opencode.ai/v2/install | bash
```

This separation keeps the OpenCode application lifecycle independent from the personal configuration lifecycle.

## Security

Never commit API keys, OAuth tokens, provider credentials, service passwords, `.env` files, generated sessions, caches, or dependency directories. The repository's `.gitignore` excludes common secret and machine-local artifacts.

Because the bootstrap is executed with `curl | bash`, review the installer and pin a release tag when deterministic installation matters. Use a public repository for the remote bootstrap flow unless you replace it with an authenticated distribution mechanism.

## Design principle

```text
GitHub repository
      │
      ├── portable OpenCode behavior
      │     ├── config
      │     ├── agents
      │     ├── commands
      │     ├── skills
      │     ├── plugins
      │     ├── tools
      │     └── themes
      │
      └── installer

Machine-local state
      ├── provider credentials
      ├── OAuth tokens
      ├── sessions
      ├── cache/state
      └── other secrets
```

Git is the source of truth for portable environment behavior. OpenCode's credentials and runtime state remain local to each device.
