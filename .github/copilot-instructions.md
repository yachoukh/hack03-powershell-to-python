# Copilot instructions

Read `AGENTS.md` first; it is the authoritative repo guidance for Copilot CLI and Copilot coding agent.

VS Code Copilot notes:

- Use `@workspace` to ground answers in `docs/behavior-spec.md`, `legacy/`, and `python/tests/`.
- Prefer small prompts that ask Copilot to port one PowerShell function or generate one test table at a time.
- Use the MCP servers in `.vscode/mcp.json` when checking PowerShell `ShouldProcess` semantics or Azure SDK shapes.
- Do not accept suggestions that weaken dry-run safety, case-insensitive tag handling, or offline test isolation.
