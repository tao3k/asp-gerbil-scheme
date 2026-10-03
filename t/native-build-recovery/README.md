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

## Shared-output writer counterexample and lease experiment

`writers.py` starts two independent compiler processes with sources 42 and 43,
identical module IDs, and one shared output root. Each controlled backend captures
its generated Scheme input before acknowledging the pause; real native gsc then
writes the original shared `.o1` path using `-o`. Two single-writer runtime checks
verify this instrumentation. This fixes the producer inputs for the experiment;
it does not measure the frequency of naturally occurring races.

```sh
env -u SDKROOT -u DEVELOPER_DIR python3 t/native-build-recovery/writers.py \
  --make-source /opt/homebrew/Cellar/gerbil-scheme@0.19/0.19.2591dcd.patchf5cedd8168cb/src/std/make.ss \
  --patch t/native-build-recovery/installed-make.patch \
  --native-gsc /opt/homebrew/Cellar/gerbil-scheme@0.19/0.19.2591dcd.patchf5cedd8168cb/current/bin/gsc \
  --output /private/tmp/gerbil-writer-study
```

With release order B then A, B publishes a receipt and native import returns 43.
A then overwrites the native objects and fails the source guard. B's receipt and
input snapshots remain byte-identical, its warm build skips compilation without
changing output bytes, and native import returns 42. A's rejection does not revoke another
writer's receipt. In release order A then B, the final runtime is 43. The terminal
marker `WRITER-GAP-REPRODUCED-AND-LEASE-EXPERIMENT-OK` records the counterexample
and bounded prototype checks; it does not qualify concurrent output support.

The runner also injects an experimental directory claim into its temporary make
copy. Atomic directory creation acquires one canonical output root before planner
imports; competing builds and cleaning fail immediately, before backend capture.
Success releases the claim. Exceptions or frontend death leave it in place. The
owner-death experiment kills only the frontend and requires each captured
backend to acknowledge a new probe after its death, checks that a new writer is rejected, then kills the owned backend group
and observes the captured processes are absent before explicit removal
of this test-only claim and successful recovery. An initial broad clean assertion
was corrected to check the expected native inventory: compiler intermediate files
outside that inventory are not required to disappear.

The directory claim prototype is **not applied to the retained compiler patches**.
It demonstrates why a claim must outlive a failed frontend whose backend jobs can
still write. It has no owner registry, automatic stale recovery, path alias or
nested-root protocol, production timeout/wait policy, or coordination with runtime
readers. Failure recovery deliberately sacrifices availability until quiescence
is proved. Retaining it would change the previously qualified automatic backend
failure recovery into operator-mediated recovery. Do not copy its temporary cleanup into production as PID-only recovery.

Directly importing `:std/os/flock` into make is also not yet justified: the local
stdlib build entry imports make before executing the build spec that contains the
native flock target. Its FFI and clean-bootstrap behavior require qualification.
An automatically released advisory lock must additionally account for surviving
backend children; frontend death alone is not proof that native writes stopped.

The next implementation contract needs an output namespace identity, an exclusive
claim covering planning, compile jobs, receipt publication and cleaning, and a
failure transition based on executor quiescence. A persistent claim needs an
operator-visible recovery record and a fenced reclamation protocol. An isolated
generation design instead needs producer-specific outputs, whole dependency
closure publication, and readers pinned to one generation. Neither reader
consistency nor full output atomicity follows from a unique `.tmp` name or a
per-invocation mutex. Exact results and source digests are in
`31.18-shared-output-writer-study.json`. The v3 compiler remains undeployed and
concurrent writers remain unsupported by the retained patches.

The writer study completed 25 recorded probes across single-writer controls,
both overlap orders, lease contention/cleaning, owner death, and explicit recovery.
The counterexample is retained as a known failure, not converted into acceptance.

Source inspection of the installed compiler base shows that executor close joins
workers before raising its recorded backend error. Normal make calls that drain
only after make-build returns. A production release-on-error design must cover
frontend planning/worker failures as well as backend errors and preserve automatic
recovery only after all write-capable jobs are quiescent. This source observation
is not an additional runtime qualification of those failure paths.

## Frontend failure must precede native drain

The earlier v3 make copy returned a frontend error while another frontend action
and native backend jobs remained active. Releasing that delayed action after the
error returned let it submit two more native jobs. Draining only the queue visible
at the first error notification therefore does not establish quiescence.

The current amendment keeps the v3 receipt format. Workers post errors to their
module completions and the barrier while continuing to finish queued independent
work. Coordinators propagate dependency errors to their own completions. The main
frontend waits for every coordinator, closes the work channel, joins every worker,
and then raises the recorded error. Installed make drains the native executor on
that failure path before rethrowing the frontend cause. A secondary backend error
is reported without replacing that first cause; no receipts are published for the
failed fixture invocation.

The candidate projection preserves its contexts, shared job slots, and session
executor API. It retains the frontend error around the session-owned native drain,
because session close can otherwise replace the producer error with a backend
error. Its matching compiler build remains unqualified; installed expansion still
fails at the preexisting `call-with-compile-job-slot` interface.

```sh
just audit-native-frontend \
  /opt/homebrew/Cellar/gerbil-scheme@0.19/0.19.2591dcd.patchf5cedd8168cb/src/std/make.ss \
  t/native-build-recovery/installed-make.patch \
  /opt/homebrew/Cellar/gerbil-scheme@0.19/0.19.2591dcd.patchf5cedd8168cb/current/bin/gsc \
  /private/tmp/gerbil-frontend-qualification
```

`frontend.py` injects controlled worker/coordinator exceptions only into a temporary
make copy. A good target has acknowledged live native jobs, a late frontend action
is held, and another target depends on the failed target. Qualification checks
that make does not return with either gate held, releases the late action to submit
its jobs, and then releases native compilation. On return all four acknowledged
direct backend PIDs are absent. Tests preserve the frontend cause even when real
native gsc also fails with an invalid C option. The same Gerbil process then builds
all four modules, reuses them without writing files, and fresh processes import
values 42, 43, and 44.

The aggregate has four seven-probe cases: worker failure, secondary backend failure,
coordinator failure, and an experimental directory claim with secondary failure.
The claim remains held during frontend/native work and is released on the repaired
ordinary-error return, allowing automatic same-process recovery. That prototype is
not in either retained compiler patch. Forced owner death still cannot execute its
release handler and requires a fenced recovery design; path aliases, nested roots,
cleaning/reader coordination, and production claim ownership remain open.

The native completion gates were also rerun for the exact amended installed source:
9 live-input, 7 content identity, 10 snapshot/v2 migration, 17 recovery, 4 interruption,
and 6 strict receipt-format probes. Total qualification is 81 recorded local probes,
plus a separate two-observation early-return counterexample. The retained receipt
schema is unchanged, so a v3-to-v3 control correctly reuses a valid record; the
migration gate uses an actual v2 source. No rebuild is claimed merely because this
lifecycle patch changed. Direct full module expansion passed. Compiler sources
remain unchanged and no compiler patch is deployed. See
`31.19-frontend-native-drain-receipts.json` for digests and exact results.

This qualifies ordinary exceptions and finite, responding jobs in the controlled
acyclic fixture. It does not add cancellation of queued independent work, a runtime
reader transaction, multi-writer support, candidate bootstrap, or forced-death
quiescence. Historical writer counterexamples and lease-abandonment results in
31.18 belong to their recorded earlier v3 source and are not reattributed here.

## Namespace aliases and escaped backend lifetime

`namespace.py` studies the current repaired make source with an isolated directory
claim wrapper. Neither this claim nor generation selection is applied to the
retained compiler patches.

```sh
just audit-native-namespace \
  /opt/homebrew/Cellar/gerbil-scheme@0.19/0.19.2591dcd.patchf5cedd8168cb/src/std/make.ss \
  t/native-build-recovery/installed-make.patch \
  /opt/homebrew/Cellar/gerbil-scheme@0.19/0.19.2591dcd.patchf5cedd8168cb/current/bin/gsc \
  /private/tmp/gerbil-namespace-study
```

| Controlled case | Result | Contract boundary |
| --- | --- | --- |
| Two spellings of one output root, via a symlink | The competing writer is rejected before compilation | A claim inside that root reaches the same physical directory |
| Distinct canonical roots whose module subdirectories alias one shared directory | Both claims succeed; B returns 43, A writes 42, B skips warm compilation and returns 42 | Canonical root equality does not establish disjoint compiler write sets |
| Frontend and original process group killed; backend children started their own sessions | Both children acknowledge a new probe after direct wrappers disappear | Original process-group death does not prove all write-capable descendants are dead |
| Deliberate group-only reclamation in the owned shared-output fixture | B completes with 43; escaped old jobs then overwrite it to 42 | Recovery counterexample; the claim removal is confined to the scratch fixture |
| Two private output generations, with a reader pinned to completed B | Old A writes 42 only in generation A; B objects and selector stay unchanged and its reader returns 43 | Output isolation can protect the new generation without reclaiming the old claim |

The alias and detached-worker controls capture each producer's Scheme input before
acknowledgment and invoke real native gsc with the original object destination.
Detached workers are explicit test instrumentation using a new process session;
this does not claim that unmodified gsc ordinarily detaches or estimate race
frequency. All process groups and any removed claims belong to this temporary
fixture. The shared-output counterexample knowingly removes a test-only claim
while escaped workers are alive to falsify group-only recovery.

The generation control creates fresh, separate output roots and atomically writes
a small test selector for completed B. A fresh reader copies that root into its
load path before import. The abandoned A claim stays in place; A's missing
completion receipt stays missing even after its real objects finish and import as
42. B's selector and output bytes remain unchanged after those old writes, and
its warm build compiles nothing. This proves isolation for the simple two-object
fixture and an explicitly pinned fresh-process reader. It is not a production
publication protocol, full dependency closure, syscall confinement, generation
allocator, or hot module-cache switching.

The study records 37 observations over 21 Gerbil process invocations (19 completed
commands and two deliberately killed frontends). The terminal marker is
`NAMESPACE-ALIASES-ESCAPED-BACKENDS-AND-GENERATIONS-STUDIED`, not concurrent-writer
acceptance. See `31.20-native-namespace-generation-study.json` for exact identities,
control records, and logs. Both retained compiler patch digests remain unchanged;
the earlier 81-probe compiler qualification is not counted as rerun here.

The next implementation should allocate a fresh producer generation and never
reuse its path for another producer while old jobs can still write. Publication
needs a separately owned selector and a fencing token: an old still-live frontend
must not publish after its authority is superseded. Readers must pin one admitted
generation including its dependency closure. Reclaiming old storage needs its own
quiescence/reader-retention contract; switching to a new generation does not prove
that old storage is safe to delete. A root-only lock or PID/process-group absence
cannot substitute for those contracts. Root alias checks are point observations,
not protection against subsequent pathname replacement.


### Publication authority and application closure

`publication.py` builds two real native modules, `publication/app` and its
`publication/dep` dependency, in fresh private roots using the unchanged repaired
installed make source. A cooperating Python broker owns publication authority.
Its monotonically increasing token is issued under the same advisory file lock
used for admission and selector replacement. Issuing a new token immediately
supersedes the previous publisher; an invalid candidate leaves the active selector
unchanged. A successful token cannot be reused during an uninterrupted run.

```sh
just audit-native-publication \
  /opt/homebrew/Cellar/gerbil-scheme@0.19/0.19.2591dcd.patchf5cedd8168cb/src/std/make.ss \
  t/native-build-recovery/installed-make.patch \
  /opt/homebrew/Cellar/gerbil-scheme@0.19/0.19.2591dcd.patchf5cedd8168cb/current/bin/gsc \
  /private/tmp/gerbil-publication-study
```

| Control | Observation |
|---------|-------------|
| Old publisher checks token, pauses, and later atomically replaces the selector | B initially imports as 43; resumed A replaces B and a fresh selector reader imports as 42 |
| Old publisher checks again inside the grant/publication lock | A exits 70 after token 2 supersedes token 1; selector bytes stay unchanged and a fresh reader imports as 43 |
| Fresh readers reuse the root pinned before A resumes | Readers of pinned B import as 43 in both controls |
| Entry module retains a completion receipt but dependency files are absent | With an explicit alternate dependency load root, import succeeds with 101 instead of 43 |
| Admission checks the explicit application graph and sealed inventory | Missing graph node, omitted dependency inventory, missing dependency files, and changed dependency object bytes are rejected; the previous selector stays unchanged |
| Complete two-module closure and current unspent token | Publication succeeds and selected runtime imports as 43; token replay is rejected |

The sealed inventory binds six artifact paths per module: SSI, two native
objects, completion receipt, source snapshot, and interface snapshot. This is an
explicit fixture graph and a successful-build-derived byte inventory, not a
parser of arbitrary completion receipts or a general dependency discoverer.
Installed runtime dependencies remain external. Hashing the supplied files does
not itself prove that their bytes were produced by a trusted compiler.

All writers in this experiment cooperate with `flock`. Token checks, admission,
and selector replacement occur while that lock is held. Output roots are assumed
quiescent and unchanged during validation and use; the lock does not constrain
backends, pathname replacement, or writes to generation storage. The root-only
control uses a deliberately configured fallback search path, not an assertion
that every reader has such a path.

Authority and active selector are separate atomic replacements without `fsync`.
This experiment does not establish crash/power-loss consistency, transactional
single-use tokens across interruption, distributed fencing, or authenticated
broker access. It does not test a long-lived Gerbil process switching its module
cache: every runtime check is a fresh process with an explicitly pinned load root.
Reader retention, general dependency extraction, storage reclamation, and
production compiler integration remain open. The broker and its controls only
operate on runner-owned scratch paths.

See `31.21-native-publication-closure-study.json` for exact observations, hashes,
and evidence boundaries. These controls do not rerun the earlier 81 compiler
probes or the 37 namespace observations.
