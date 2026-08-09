# Gerbil Scheme Language Project Harness
This repository is the Gerbil Scheme language provider for `agent-semantic-protocols`.
The implementation is pure Gerbil/Scheme. Parser authority comes from Gerbil's native reader and expander data:
- `read-syntax-from-file` reads source with the Gerbil readtable.
- `stx-source` gives source locations for top-level forms.
- `syntax->datum` is used only as the compact projection layer for search and query packets.
- Future export/type enrichment should use `import-module` and module-context facts, following Gerbil's own `gxtags` pattern.
No Python parser is part of this harness.
## Policy Philosophy
Gerbil policy is the project mechanism for helping an agent become a better Gerbil Scheme programmer. It is not a hardcoded rewrite table. A good policy exposes parser-owned evidence, points at Gerbil/Gambit idioms, and gives the agent enough context to choose a high-quality repair.

The policy layer should therefore prefer facts over string guesses, scenarios over slogans, and misuse guards over one-off style preferences. When several idiomatic repairs are valid, diagnostics should teach the boundary and leave the final code shape to the agent.

The full policy direction is documented in `docs/50-59-policy/51.00-policy-philosophy.org`.
The macro/module research root is `docs/10-19-research/11.12-gerbil-macro-module-system-research.org`; use it before turning advanced Gerbil macro or module features into parser facts, policy warnings, or scenarios.
The broader advanced-feature backlog is `docs/10-19-research/11.13-gerbil-advanced-feature-exploration.org`.
## Package Workflow
Build the declared library modules through Gerbil's upstream build script:
```sh
gxi build.ss compile
```
When a Nix SDK is inherited into a Homebrew Gerbil process, use the same command
with a process-local SDK override: `env SDKROOT= gxi build.ss compile`.
Run package tests through upstream `gxtest`:
```sh
gxtest t/...
```
## Building Framework
The harness building framework is documented in `docs/30-39-building/31.01-building-framework.org`.
It keeps Gerbil `std/make` as the compile executor while adding explicit build stages,
receipts, package stage ordering, and performance gates.
## Downstream gxtest Quickstart
Build this harness from its checkout into the global Gerbil package store:
```sh
gxi build.ss compile
```
Downstream packages should depend on the installed harness package in `gerbil.pkg`:
```scheme
(package: your/package
 depend: ("github.com/tao3k/gerbil-scheme-language-project-harness"))
```
Add a small `gxtest` fixture, for example `t/project-policy-test.ss`:
```scheme
;;; -*- Gerbil -*-
(import :std/test
        :gslph/src/policy/gxtest)
(export project-policy-test)
(def project-policy-test
  (make-project-policy-test "."))
```
Then run:
```sh
gxtest t/project-policy-test.ss
```
Gerbil package-manager state belongs under the global `~/.gerbil` store. Do not create or commit a repository-local `.gerbil` directory for this harness. For the full onboarding contract, see `docs/60-69-user/60.01-downstream-gxtest-onboarding.org`.
## Alignment Target
This first native version aligns the common provider surface:
- compact text by default
- `agent doctor --json` provider metadata for protocol consumers
- `search workspace`, `prime`, `owner`, `owner items`, `symbol`, `import`, `lexical`, and `ingest`
- ASP-owned exact projection backed by the provider-native typed request
- exact source and callable skeletons via `asp gerbil-scheme query --selector ... --projection source|callable-skeleton`
- `agent doctor --json`
- `agent guide`
The next implementation layer should enrich this with expanded module exports, phase-aware import/export facts, and compiler/type facts from Gerbil's expander and compiler modules.
