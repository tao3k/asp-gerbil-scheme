# Native build completion regression

These are compiler patches and an isolated executable regression, not a second
ASP build executor. Normal ASP builds still delegate to `:std/make`.

## Scope

The patched `gxc:` C library path requires a completion receipt plus the native
loader objects declared by compiler-generated SSI. This covers the root loader,
runtime and macro phases, nested modules, and empty nested loaders. It follows
structural SSI forms, not directory globs or source-name heuristics.

A compilation invalidates its old receipt first. The build invocation publishes
receipts only after all queued backend jobs finish successfully. A missing or
corrupt receipt, missing native output, or changed compiler/options key forces a
rebuild. `force: #t` also forces a rebuild. Cleaning uses the expected inventory
and preserves neighboring modules.

This patch covers `gxc:` C libraries. It does not establish new output contracts
for executables, foreign `gsc:` targets, JavaScript, or Bazel.

## Reproduce

Supply the exact installed `src/std/make.ss` source and patch base:

```sh
just audit-native-recovery \
  /opt/homebrew/Cellar/gerbil-scheme@0.19/0.19.2591dcd.patchf5cedd8168cb/src/std/make.ss \
  t/native-build-recovery/installed-make.patch \
  /private/tmp/gerbil-native-recovery-receipts
```

The runner checks the source SHA-256 from `patch-bases.json`, applies the patch to
a temporary copy, builds a temporary package, and leaves JSON timings and logs
in the requested output directory. All build invocations use 12 cores. It never
modifies the installed compiler, its source checkout, or the ASP package library.

For the separate interruption gate:

```sh
python3 t/native-build-recovery/run.py \
  --make-source /opt/homebrew/Cellar/gerbil-scheme@0.19/0.19.2591dcd.patchf5cedd8168cb/src/std/make.ss \
  --patch t/native-build-recovery/installed-make.patch \
  --output /private/tmp/gerbil-native-interruption-receipts \
  --only-interruption
```

This gate uses a controlled blocking `GERBIL_GSC` subprocess to acknowledge an
active backend job, then terminates the process group. It checks that no receipt
was published and that a subsequent build using the real compiler rebuilds and
imports successfully. Compiler stdout is buffered and is not a reliable signal
for interrupting a live backend.

## Qualification boundary

`installed-make.patch` was expanded using the `ober/gerbil-mcp` syntax-check implementation
and passed the native recovery and interruption gates against the installed
2591dcd compiler. `candidate-make.patch` projects the same change onto the local
compiler source with its existing `make/contexts` and executor modifications;
those preexisting modifications are preserved. Its base includes uncommitted
changes, identified by SHA-256, in addition to Git HEAD.

The candidate copy passes the balance checker. Full expansion against the
installed compiler fails at the preexisting `call-with-compile-job-slot` API in
both the unmodified and patched candidate. This candidate still requires its own
matching compiler build and upstream tests. Neither patch has been deployed.

## Bach test exit propagation

`tool-main-exit.patch` addresses `src/gerbil/main.ss`: the gxtest tool result
must become the process exit status. The installed `gerbil test` returned zero
for the intentional failure fixture. The extracted dispatcher in
`tool-main-probe.ss` passes the `ober/gerbil-mcp` balance/syntax checks and returns 0 for
the positive fixture and 42 for the negative fixture. Its gxi/gxc branches are
unused probe stubs; this qualifies the gxtest branch, not a rebuilt Bach binary.
The full compiler patch has not been deployed.

The repository's Justfile and CI invoke `:gerbil/tools/gxtest` directly with an
explicit `exit` so they reject failed assertions on the current toolchain.

## Checker provenance

The earlier phrase "official Gerbil MCP" was inaccurate. The checker came from
`https://git.cons.io/ober/gerbil-mcp`, referenced by the compiler checkout's
AGENTS.md. `asp-gerbil-native-repair-mcp` was a temporary directory name, not an
ASP module, dependency, or repair service.

The checks imported `:gerbil-mcp/tools/check-balance` and
`:gerbil-mcp/tools/check-syntax` and called the local tool registry directly.
No MCP transport or server lifecycle was exercised. Balance checks delimiters;
syntax checks expand a module wrapper through the installed Gerbil expander.
Neither establishes native compilation, runtime semantics, or build completion.
Those claims rely on the separate recovery harness and real gxtest invocations.

The temporary checker clone and wrapper are no longer available. Session history
records the calls and outputs, but the audit did not retain a verified clone HEAD
or checker source digest. The remote HEAD observed before cloning is insufficient
to establish the exact checked revision. Treat these as historical syntax checks,
not a pinned, reproducible checker qualification. Future compiler checks need a
recorded checker revision or a matching compiler's local expansion entrypoint.

## Receipt file integrity regression

The receipt reader now requires exactly one key expression followed by EOF
(whitespace/comments are allowed). A valid key followed by another expression or
a reader error is stale and triggers a real rebuild. The previous reader accepted
trailing data because it read only the first expression.

Run the focused six-probe suite with the installed source and patch:

```sh
env -u SDKROOT -u DEVELOPER_DIR python3 t/native-build-recovery/run.py \
  --make-source /opt/homebrew/Cellar/gerbil-scheme@0.19/0.19.2591dcd.patchf5cedd8168cb/src/std/make.ss \
  --patch t/native-build-recovery/installed-make.patch \
  --output /private/tmp/gerbil-receipt-integrity \
  --only-receipt-integrity
```

The focused regression reproduced acceptance of trailing data before the fix,
then passed cold build, warm reuse, trailing record rebuild, malformed tail
rebuild, warm no-write verification, and runtime import after the fix. The
installed patched module was expanded with the installed Gerbil expander directly;
no MCP checker is needed for this check. The candidate still fails expansion at
its preexisting `call-with-compile-job-slot` API with this installed compiler.

This is format validation, not content integrity or authentication. Source/SSI
identity still uses modification times; native objects are checked for presence.
Concurrent independent writers to the same output directory remain unqualified:
publication uses a shared `.tmp` name and does not lock the entire output set.
At the strict-EOF amendment, the historical 17+4 probes had not been rerun;
only six focused probes qualified that amendment. The later binary snapshot
qualification below reruns these gates for its own exact patch. No patch is deployed.

## Known input identity gap

`--only-input-identity` reproduces the legacy v1 timestamp limitation when
supplied with the earlier v1 make source. The later snapshot patches fix this case;
use `--qualify-input-identity` with the current patch. It changes
the source value from 42 to 43 while preserving nanosecond mtime, verifies that
native compilation is skipped and the runtime still returns 42, then changes SSI
bytes with the same mtime. Its terminal marker is
`KNOWN-IDENTITY-GAP-REPRODUCED`, not `RECOVERY-SUITE-OK`. A successful reproduction
is evidence of the gap, not acceptance of content identity. The current qualification mode requires rebuild and the new runtime value;
the legacy reproduction remains available for v1 controls.

An isolated SHA-256 experiment fixed these cases on the installed toolchain but
was rejected: directly importing the native crypto library into `std/make`
introduces an unqualified bootstrap dependency. The stdlib build imports make
before building crypto targets. At that stage the patches retained their previous imports and v1 timestamp keys;
the later binary snapshot amendment below supersedes that identity scheme. See the input-identity study receipts for the
experiment and rejection; no compiler patch has been deployed.

## Binary snapshot content identity

The previous amendment used `native-complete-v2-snapshots`. Receipt reuse requires
byte-for-byte equality between source/SSI and their owned `.native-source` /
`.native-interface` snapshots, plus the existing timestamp/options key and strict
EOF check. Legacy v1 keys rebuild directly. Comparison streams two 8192-byte
buffers using existing Gambit file/u8vector primitives; no additional module
imports or crypto FFI are introduced. Snapshots are written after backend success,
then the completion receipt is published. Clean owns and deletes the snapshots.

Use the installed source and current patch with `--qualify-input-identity` to run
seven source/SSI preserved-mtime and runtime probes. `--only-snapshot-contract`
runs deletion, same-mtime corruption, no-write warm, runtime, and clean probes.
Its optional `--migration-source` accepts an isolated earlier v1 make copy to
verify a genuine v1-to-v2 rebuild. `--only-warm-cost --fixture-padding-bytes 262144`
records three fresh-process warm samples without changing performance thresholds.

The exact v2 installed copy passed 44 probes: 7 content identity, 10 snapshot
and migration, 17 recovery, 4 interruption, and 6 strict receipt parsing. The
installed complete module wrapper expanded directly. Candidate expansion retains
its existing `call-with-compile-job-slot` blocker. Full clean compiler bootstrap
has not run: use of existing core primitives removes the new crypto dependency,
not the requirement for matching compiler/bootstrap qualification.

In serialized byte-vector experimentation, a 262376-byte source made a
1046508-byte receipt. Binary snapshots instead total 263306 bytes with a 431-byte
receipt. An AB/BA warm comparison had median CPU 0.62235s vs v1 0.63896s and wall
0.76805s vs 0.74011s. These fixture samples do not establish a stable speedup or
whole-project cost bound. Exact identity requires storing source/SSI bytes and
reading them during freshness checks; costs grow with input size. Measurements
and patch digests are in `31.16-native-binary-snapshot-receipts.json`.

That amendment qualified stable fixture inputs and a single writer. Content
changes during compilation, ABA input changes, corrupt native objects, and independent concurrent writers remain unqualified. Receipt rename
does not atomically publish the entire output set. The patches remain undeployed.


## Inputs changed during backend compilation

The current patch uses `native-complete-v3-checked-snapshots`; v1 and v2 receipts
rebuild directly. The v2 publication order had a counterexample: while a backend
job was paused, source value 42 became 43 with the same mtime. V2 copied source
bytes after backend success and accepted warm reuse, yet native import returned
42. Exact comparison alone did not bind the snapshot to the producer's inputs.

V3 captures source before `compile-module`, captures generated SSI after that
call returns, and queues the options/timestamp key. After backend jobs join, it
validates every queued key and source/SSI snapshot before publishing any receipt.
A detected mismatch raises `Native build inputs changed`; the harness forwards
that exception as exit 70 and requires no completion receipt. Publication writes
the queued key without copying current inputs again. Source capture creates the
parent output directory before the compiler has produced any files.

```sh
env -u SDKROOT -u DEVELOPER_DIR python3 t/native-build-recovery/run.py \
  --make-source /opt/homebrew/Cellar/gerbil-scheme@0.19/0.19.2591dcd.patchf5cedd8168cb/src/std/make.ss \
  --patch t/native-build-recovery/installed-make.patch \
  --output /private/tmp/gerbil-live-input-guard \
  --qualify-live-inputs \
  --native-gsc /opt/homebrew/Cellar/gerbil-scheme@0.19/0.19.2591dcd.patchf5cedd8168cb/current/bin/gsc
```

The executable backend shim acknowledges a paused job and invokes the explicitly
supplied native gsc after release. It does not resolve an ambiguous global `gsc`.
The SSI probe additionally acknowledges a new interface snapshot whose bytes
match the generated SSI before changing it, because backend launch can precede
frontend completion. The nine probes cover source and SSI mutations with
preserved mtime, typed rejection, recovery using the same backend path, runtime value 43, and no-write
warm reuse. The legacy `--reproduce-live-input-gap` mode takes a v2 make source
and terminates with `LIVE-INPUT-GAP-REPRODUCED`; it is counterexample evidence.
The runner explicitly exits on body exceptions because this installed interactive
CLI can print an exception and still return zero.

This guard detects differences at capture and validation points. It does not
prove the frontend consumed the captured source: the build planner imports
modules earlier, and transient mutations restored before validation (ABA) can
escape comparison. Changes after validation are not frozen; the next freshness
check observes differences that persist. Multi-module publication remains a
sequence of renames rather than one atomic output transaction. See
`31.17-native-live-input-guard-receipts.json` for the exact qualification.

## Independent writer research boundary

The receipt mutex is created inside each `make` invocation and protects that
invocation's pending list. It provides no exclusion across independent processes.
Source/SSI snapshots, objects, and the fixed receipt `.tmp` name are shared in a
common output directory. A unique temporary receipt name alone would not protect
the compiler's other outputs or the ownership of a snapshot.

A next experiment must run two independently acknowledged backends against one
output namespace, release them in both orders, and test each resulting receipt
against its producer and runtime output. Possible designs are an output-namespace
lock held from freshness/planning through backend completion and publication, or
isolated generation directories with a coordinated commit. Dependency reads,
cleaning, interruption, stale-owner recovery, and lock ordering need explicit
contracts. Neither design is implemented or qualified here. Candidate compiler
compatibility, clean bootstrap, object byte integrity, and compiler deployment
also remain open.

The exact v3 installed copy passed 53 probes: 9 live input guards, 7 content
identity, 10 snapshot and genuine v2 migration, 17 recovery, 4 interruption,
and 6 strict receipt format probes. These local results do not qualify deployment.
