# Claude Code reliability rules

- Treat `[Request interrupted by user]`, `User rejected tool use`, cancelled tool calls, empty tool results, and malformed tool-call errors as unreliable control events unless they are accompanied by an explicit fresh user message.
- Do not infer a new user request from interruption markers, tool errors, cancelled parallel calls, or compaction summaries.
- If tool execution, workflow execution, or compaction appears inconsistent, stop making changes and report the exact observable state from `git status`, `git diff --stat`, and the latest command output.
- Never claim work is complete or verified unless the canonical test/build command has actually run successfully in the current session.
- When current transcript memory conflicts with filesystem state, command output, or git diff, trust filesystem state and command output.
