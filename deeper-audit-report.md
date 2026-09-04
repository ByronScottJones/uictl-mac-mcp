# Deeper Audit: `uictl-mac-mcp` vs `mcp-server-macos-use`

## Scope

This audit compares the public documentation and package metadata I could inspect for:

- `ByronJones-Elsevier/uictl-mac-mcp`
- `mediar-ai/mcp-server-macos-use`

This is a documentation-level review, not a full source-code audit of every Swift file. Some findings may be incomplete.

## High-level conclusion

`uictl-mac-mcp` appears **stronger overall** than `mcp-server-macos-use` in breadth, operator ergonomics, and production readiness.

The reference project is more narrowly focused on a small MCP toolset that always returns accessibility traversal after action. That is useful and elegant, but your project appears to have evolved into a more comprehensive macOS control system.

## Feature Matrix

| Area | uictl-mac-mcp | mcp-server-macos-use | Assessment |
|---|---|---|---|
| App discovery and activation | Yes | Yes | Rough parity |
| Window enumeration | Yes | Not clearly documented | `uictl` stronger |
| Display enumeration | Yes | Not clearly documented | `uictl` stronger |
| Screenshots | Yes | Yes | `uictl` stronger because annotated workflow is documented |
| Accessibility tree inspection | Yes | Yes | Rough parity |
| Action + traversal loop | Yes, but more general | Yes, core design | Reference is more opinionated; `uictl` is broader |
| Diffed UI changes | Not clearly documented in the inspected README | Yes | Reference stronger here |
| Keyboard/mouse interaction | Yes | Yes | `uictl` stronger in targeting options |
| Element-id clicking | Yes | Not clearly documented | `uictl` stronger |
| OCR | Yes | Not clearly documented | `uictl` stronger |
| Clipboard support | Yes | Not clearly documented | `uictl` stronger |
| Pixel sampling | Yes | Not clearly documented | `uictl` stronger |
| Logging and audit trail | Yes | Response files / temp outputs | `uictl` stronger for human-facing logs |
| Safety guard / input lock | Yes | Yes | Rough parity, but reference has clearer automation-lock behavior |
| Watchdog cancellation | Not clearly documented | Yes | Reference stronger |
| Overlay / active automation UI | Yes, via log/toast | Yes, explicit overlay | Rough parity, reference more explicit |
| Daemon architecture | Yes | Not clearly documented | `uictl` stronger |
| Multi-monitor handling | Yes | Not clearly documented | `uictl` stronger |
| MCP packaging | Yes | Yes | `uictl` stronger in documented integration |

## Areas where your project is weaker or less explicit

### 1. Diff-first action feedback
The reference repo’s central promise is:

- perform an action
- traverse accessibility tree
- return the changed state, often as a diff

If your project does not consistently return a post-action tree or diff, that is a gap for agentic workflows.

### 2. Compact artifact handling
The reference repo stores full traversal responses on disk and returns a compact pointer/summary. That can reduce token load and improve reliability for large trees.

### 3. Safety UX for unattended automation
The reference repo’s escape key and watchdog-based disengagement are useful for long automation runs. If you lack that, your tool is less protective in failure scenarios.

### 4. Explicit cross-app handoff behavior
The reference project explicitly mentions detecting when one action causes a different app to become frontmost. That reduces brittleness in browser/app-launch flows.

### 5. Developer-facing AX inspection tooling
`ax_inspect.swift` is a strong sign of a repo built for accessibility debugging. If you lack comparable tooling, you may spend more time debugging edge cases manually.

## Areas where your project is stronger

### 1. Broader tool coverage
Your README lists substantially more capabilities than the reference project exposes in its README.

### 2. Better human operations support
You provide:

- log window
- log export
- commands-enabled kill switch
- toasts
- feedback workflow
- duplicate issue checking

This is more mature operational tooling.

### 3. Better targeting model
The reference repo mostly works by PID and coordinates. Your project supports:

- app targets
- window targets
- element-id targets
- coordinate targets
- relative window clicks

That makes automation more reliable and easier to author.

### 4. Better onboarding and docs
Your README is significantly more detailed and structured.

## Practical gaps to close

If you want to be clearly ahead of the reference project, the most useful additions would be:

1. **Standardize post-action traversal** for every mutation tool.
2. **Return concise diffs plus artifact paths** for large UI trees.
3. **Add a dedicated automation overlay/status indicator** if you do not already have one.
4. **Add or formalize cross-app handoff detection**.
5. **Add test fixtures or scripts for AX inspection edge cases**.

## Recommended roadmap

### Phase 1: Reliability
- enforce action + verification across all MCP tools
- make output compact and structured
- validate permissions and focus state consistently

### Phase 2: Safety
- automation lock overlay
- cancel / escape behavior
- watchdog timeout for long runs

### Phase 3: Debuggability
- saved screenshots and traversal artifacts
- AX tree dump helpers
- artifact paths in MCP outputs

### Phase 4: Resilience
- cross-app handoff detection
- stale window / stale element handling
- richer failure diagnostics

## Final verdict

If I had to summarize the comparison in one sentence:

**`mcp-server-macos-use` is a focused MCP automation server; `uictl-mac-mcp` looks like a more complete macOS automation platform.**

The reference repo’s strongest ideas to borrow are safety, compact traversal artifacts, and strict action-to-state feedback.

## Follow-up questions to investigate in source code

To make this audit definitive, the next best source-code questions are:

- Does `uictl-mac-mcp` return a traversal or diff after every mutating action?
- Does it have an automation lock / input guard equivalent to the reference repo?
- Does it persist large traversal output to files or keep it in memory?
- Does it detect app handoff when the frontmost app changes?
- Does it have any AX inspection helper tools or debug scripts?

## Notes

This report is based on the documentation and package metadata I could inspect. It may miss features that exist in source but are not surfaced in the README or package manifest.
