# /quality-fix

Find and fix code quality issues in the BonhommeCore and BonhommeAccel source trees as separate atomic commits. Each commit addresses one category of issue.

## Steps

1. Scan source files for common quality issues:
   - BonhommeCore: `BonhommeCore/Sources/`
   - BonhommeAccel: `BonhommeAccel/src/`, `BonhommeAccel/include/`
2. Categories to check (one commit each):
   - Unused imports / dead code
   - Missing `Sendable` or `@MainActor` annotations where required by convention
   - Force unwraps that should be guarded
   - Inconsistent access control (missing `private` / `public`)
   - Typos in comments or string literals
   - Missing or incorrect doc comments on public API
3. For each category found:
   - List the files and lines affected
   - Apply fixes across all relevant files
   - Stage only the changed files for that category
   - Commit with message: `fix(category): description`
   - Push immediately
4. Run relevant tests after all fixes (`swift test` for BonhommeCore, `ctest` for BonhommeAccel)
5. Report summary: N categories fixed, M files changed, tests passing/failed

## Constraints

- Do NOT refactor working code or change behavior — only fix clear quality issues
- Do NOT add features, new abstractions, or speculative improvements
- Each commit must be independently revertable
- Always build and test before committing
- Push each commit right after creating it — don't batch locally
