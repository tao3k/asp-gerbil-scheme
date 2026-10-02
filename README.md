# ASP Gerbil Scheme
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
Use the thin justfile recipes, backed by Gerbil's native commands:
```sh
just deps
just build
just check-policy
just test
just clean
```
`just rebuild` runs clean, dependencies, build, and the semantic library tests
sequentially and stops at the first failure. `just clean-provider` and
`just build-provider` select the sibling provider build script.
Both scripts use `std/build-script` directly for spec, compile, clean, and meta;
no package-specific command dispatcher is needed. Link options remain owned by
PackageSpec and upstream pkg-config resolution, not by just.
When a Nix development shell exports an incompatible SDK into Homebrew Gerbil,
use a process-local override, `env SDKROOT= just build`; do not rewrite the
global toolchain or bake a host-specific SDK into the recipes.
Run selected tests through the same native environment:
```sh
just test-files t/package-build-contract-test.ss
```
## Building API
Downstream `build.ss` files import
`:asp-gerbil-scheme/building-api` for PackageSpec declarations. Its default
POO `spec-projector` slot runs the existing policy rules on source modules
selected by the native BuildSpec when `ASP_GERBIL_SCHEME_POLICY=check` is set,
before passing that same spec to `std/make`. Ordinary `just build` leaves source
currentness and compilation to `std/make` without a second parse of every
selected module. `just check-policy` enables the complete policy pass; CI uses
it for the canonical library build.
Downstream packages declare their module targets; they override or compose the
slot only when they need different admission behavior. The explicit pass reports the
selected module count and findings, and rejects error findings such as a source
file over 1000 lines. An empty target selection returns the native spec without
initializing the policy rule set; a nonempty selection loads it once through
Gerbil's module system and checks those source files.
It does not scan the workspace for another project graph.
Gerbil `std/make` remains the only graph, currentness, scheduling, and execution
owner. Optional native behavior is composed through PackageSpec and
NativeProfile POO slots; it does not add another public build framework.
Testing and benchmark capabilities are separately owned by
`:asp-gerbil-scheme/testing-api` and `:asp-gerbil-scheme/benchmark-api`.
Standalone policy inspection remains available from
`:asp-gerbil-scheme/policy-api`; the Building API default uses the same rule
set on the sources selected for this build.
Pure expansion-time generators can use the verified content-addressed sidecar
extension documented in `docs/30-39-building/31.09-verified-generated-module-artifacts.org`;
the extension projects only native `gxc:` `extra-inputs:` and never replaces
`std/make` freshness, dependency, or scheduling decisions.
## Downstream gxtest Quickstart
Build this harness from its checkout into the global Gerbil package store:
```sh
gerbil build
```
Downstream packages should depend on the installed harness package in `gerbil.pkg`:
```scheme
(package: your/package
 depend: ("github.com/tao3k/asp-gerbil-scheme"))
```
Add a small `gxtest` fixture, for example `t/project-policy-test.ss`:
```scheme
;;; -*- Gerbil -*-
(import :std/test
        :asp-gerbil-scheme/policy-api)
(export project-policy-test)
(def project-policy-test
  (make-project-policy-test "." ["src/core.ss" "t/core-test.ss"]))
```
Then run:
```sh
gerbil test t/project-policy-test.ss
```
Gerbil owns package-environment selection; use its native commands rather than
hardcoding another package store. Never commit generated `.gerbil` state.
For the full onboarding contract, see `docs/60-69-user/60.01-downstream-gxtest-onboarding.org`.
## Alignment Target
This first native version aligns the common provider surface:
- compact text by default
- `agent doctor --json` provider metadata for protocol consumers
- Runtime-owned Search Playbook discovery with Gerbil-native facts
- ASP-owned exact projection backed by the provider-native typed request
- exact source and callable skeletons via `asp query playbook --language gerbil-scheme --selector ... --projection source|callable-skeleton`
- `agent doctor --json`
- `agent guide`
The next implementation layer should enrich this with expanded module exports, phase-aware import/export facts, and compiler/type facts from Gerbil's expander and compiler modules.
