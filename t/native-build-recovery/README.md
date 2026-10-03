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


### Process interruption and a single publication record

`publication_crash.py` reuses `publication.py` admission and manifest sealing,
builds fresh native A/B application closures, and kills its own publisher process
at acknowledged checkpoints. The retained compiler patches are unchanged.

```sh
just audit-native-publication-crash \
  /opt/homebrew/Cellar/gerbil-scheme@0.19/0.19.2591dcd.patchf5cedd8168cb/src/std/make.ss \
  t/native-build-recovery/installed-make.patch \
  /opt/homebrew/Cellar/gerbil-scheme@0.19/0.19.2591dcd.patchf5cedd8168cb/current/bin/gsc \
  /private/tmp/gerbil-publication-crash-study
```

The split-record control follows the previous broker's order: replace
`active.json`, then replace `authority.json` with `spent=true`. SIGKILL between
those operations releases the advisory lock and leaves active B with an unspent
token. A fresh publisher accepts the same token with manifest A, changing the
selected native runtime from 43 back to 42. The completed module bytes were not
modified; the selector was republished with another admitted closure.

The transaction control stores schema, current epoch, spent flag, and active
publication in one `state.json`. The active record binds publication epoch,
request identifier, manifest, and its canonical JSON SHA-256. Grants and
publication share one stable advisory lock. A commit writes a unique staging
file, flushes and fsyncs it, atomically replaces the authoritative file, and
fsyncs the parent directory before returning an acknowledgement.

| Kill checkpoint | Restarted authority and selector | Retry behavior |
|-----------------|----------------------------------|----------------|
| Before staging | Token 2 unspent; active A at epoch 1, runtime 42 | Original B request commits, then runtime 43 |
| After staging file fsync, before replacement | Same A state; one abandoned staging file is ignored | Original B request commits, then runtime 43 |
| After authoritative replacement, before directory fsync | Token 2 spent; active B at epoch 2, runtime 43 on this host | Same request and manifest receive a replay acknowledgement without rewriting state |
| After directory fsync, before acknowledgement | Same complete B state, runtime 43 | Same request and manifest receive a replay acknowledgement without rewriting state |

In all four transaction cases, reusing the consumed token with another manifest
or request identifier exits 70 without changing the authoritative bytes. Issuing
token 3 rejects token 2 even when its previous request matches. Missing,
malformed, or structurally inconsistent authoritative state exits 70 and is not
reset, overwritten, or reconstructed from staging files. Fixture initialization
is an explicit separate action.

The run records 45 observations: 12 Gerbil commands, 20 completed broker commands,
five killed broker processes, and eight direct state observations. The split
control contributes one kill and the transaction control contributes four.
Raw command output hashes, fixture manifests, shared-helper identity, and source
identities are in `31.22-native-publication-process-crash-study.json`.

This tests process death at explicit local checkpoints; the OS and filesystem
remain running. Calls to fsync do not establish power-loss durability, remote
filesystem semantics, or hardware flush guarantees. A crash during grant issuance,
schema migration, lock-file replacement, hostile publishers, and general
reader/writer concurrency are not exercised. An unacknowledged committed request
is resolved by matching the currently authoritative epoch, request identifier,
and manifest digest. A newer grant supersedes that retry authority; this prototype
has no historical acknowledgement ledger or request lookup service.

The application dependency graph remains the explicit two-module fixture.
Generation storage is assumed quiescent and immutable; replay acknowledges the
committed bytes' identity without rehashing live storage. General compiler-owned
closure discovery, authenticated admission, generation lifetime retention, and
production integration remain open. Earlier studies are not rerun or counted.


### Compiler-owned application import closure

`closure.ss` projects the native expander's `module-context-import` facts through
module imports, import sets, exports, and owning contexts. It records resolved
identity, path, import kind, and relative phase. Unsupported import or nested
module-path representations fail explicitly. It does not scan source text for
imports. `closure.py` supplies an explicit seven-module build inventory, expands
those source owners, and computes reachability from the declared app entry.

```sh
just audit-native-closure \
  /opt/homebrew/Cellar/gerbil-scheme@0.19/0.19.2591dcd.patchf5cedd8168cb/src/std/make.ss \
  t/native-build-recovery/installed-make.patch \
  /opt/homebrew/Cellar/gerbil-scheme@0.19/0.19.2591dcd.patchf5cedd8168cb/current/bin/gsc \
  /opt/homebrew/Cellar/gerbil-scheme@0.19/0.19.2591dcd.patchf5cedd8168cb/current/lib \
  /private/tmp/gerbil-compiler-closure-study
```

The fixture contains a leaf, a renamed/selected leaf import, a re-export bridge,
a phase-one import with its own dependency, the app, and an unrelated built module.
The expander-derived graph reaches six modules and excludes the unrelated module.
Phase-one facts are retained, including the transitive dependency needed by that
module. Relative phases are evidence on each edge; this control does not calculate
absolute phase composition for arbitrary module graphs.

Native object paths come from the retained make patch's structural SSI walker,
`native-outputs`. The scratch copy exports a narrow wrapper solely for this study;
the walker and retained patches are unchanged. This matters because bridge has
one native object, app has three, and the other four reachable modules have two
each. The manifest binds 36 files: those 12 native objects plus four interface,
receipt, and snapshot files for each module. This replaces the earlier fixture's
fixed two-object assumption. Live source bytes must equal their completed source
snapshot before sealing the graph and artifacts.

| Control | Observation |
|---------|-------------|
| Two fresh generations with compiler-derived graphs | A returns 42, B returns 43; both admit six reachable modules and 36 artifact hashes |
| Renamed import and re-export bridge | Owning module facts retain leaf and bridge dependencies without interpreting source import spelling |
| `for-syntax` import with a transitive dependency | Phase-one edge and dependent module are included in the union closure |
| Built but unreachable module | Excluded from the selected application's artifact inventory |
| B leaf removed, with A supplied as a fallback root | Native runtime becomes 42; resolved compiler fact points outside the expected local generation and admission is rejected |
| Transitive phase dependency omitted from manifest inventory | Rejected against the compiler-derived reachable set and object paths |
| Source changed after the successful build | Source/snapshot comparison rejects sealing stale compiler evidence |

The external frontier records the explicitly imported installed list utility's
resolved interface path and SHA-256 under an explicitly supplied installation
root. Admission checks that frontier interface remains unchanged. It does not
walk external runtime/native dependencies or bind the implicit language prelude,
compiler, OS libraries, or whole installed runtime. A frontier hash is not a
complete external environment pin or a provenance proof.

Source owners are expanded in a fresh Gerbil process after compilation, with
local import resolution through the completed output root. Expansion may execute
compile-time code; this study runs authored fixture modules. It does not establish
sandboxed expansion of untrusted inputs. Membership starts from declared build
inventory and expander identities, not package-name heuristics. Generation roots
and approved external paths remain assumed stable and quiescent; alias replacement
and hostile mutation are outside this control.

This qualifies a manifest input seam. It does not replace the previous broker's
fixed admission function or deploy compiler publication. General nested modules,
weak imports, absolute phase composition, dynamic runtime loads, external closure
pinning, and integration with the single-record broker remain open. See
`31.23-native-compiler-closure-study.json` for exact facts and identities. The final
qualification records 15 observations, including 10 real Gerbil commands. Earlier
compiler, namespace, publication, and crash observations are separate evidence.


### Compiler evidence admitted by transactional publication

`just audit-native-closure-publication` runs the same fresh compiler-closure
fixtures and adds transactional publication. `publication_admission.py` registers
compiler evidence through a trusted fixture coordinator, and
`publication_integration.py` exercises independent publishing processes against
that registration. The transaction core accepts an admission callback; its
default fixed-fixture admission remains unchanged and is separately requalified.

```sh
just audit-native-closure-publication \
  /opt/homebrew/Cellar/gerbil-scheme@0.19/0.19.2591dcd.patchf5cedd8168cb/src/std/make.ss \
  t/native-build-recovery/installed-make.patch \
  /opt/homebrew/Cellar/gerbil-scheme@0.19/0.19.2591dcd.patchf5cedd8168cb/current/bin/gsc \
  /opt/homebrew/Cellar/gerbil-scheme@0.19/0.19.2591dcd.patchf5cedd8168cb/current/lib \
  /private/tmp/gerbil-closure-publication-study
```

Registration stores the compiler-derived graph, canonical manifest digest, and
source-import/output-fact hashes together with extractor, patched make, and
native gsc identities under a content-addressed receipt ID. The coordinator
registers after successful compilation, extraction, and sealing. A publisher
submits `{receiptId, manifest}`. Inside the publication transaction lock, admission
reads the broker-owned receipt, checks its content identity, compares the
candidate with the registered build, then validates artifacts and the external
interface frontier against that independently registered graph. Candidate graph
or artifact hashes cannot redefine the admission contract.

| Control | Observation |
|---------|-------------|
| Publish registered A, then registered B | Pinned fresh readers return 42 and 43; the previously pinned A root still returns 42 after B selection |
| Unknown receipt, candidate graph change, or omitted phase artifact hash | Exit 70; authority remains unspent and active A is unchanged |
| Registered receipt content changed in the owned fixture | Receipt digest mismatch exits 70; active A is unchanged |
| Native object changed after registration | Artifact digest mismatch exits 70; updating the candidate hash also fails the registered-manifest comparison |
| Old A publisher pauses after an early admission check; newer B token commits | Old publisher resumes with exit 70; B publication digest, receipt identity, and authoritative bytes are preserved |
| B publisher killed after directory fsync before acknowledgement | Restart retains a spent token and the complete registered B subject; matching request retry returns `ACK-REPLAY` without rewriting state |
| Retry with another registered subject or request identifier | Exit 70 without changing committed state |
| Storage changed after committed publication | Matching historical request still returns `ACK-REPLAY`; a new reader's pin/admission rejects the changed object |
| Owned fixture restores the original bytes | Reader admission succeeds again and fresh selected runtime returns 43 |

The last control separates committed-request acknowledgement from current storage
admission. It does not authorize a reader merely because a retry is acknowledged.
A pin reads one authoritative transaction record and revalidates its registered
subject before returning publication epoch, request, digest, receipt ID, and load
root. Each runtime check is a fresh process using that pinned root; there is no
live Gerbil module-cache switch or reader-retention service.

Receipt registration is a trusted coordinator action on broker-owned scratch
storage. Content addressing detects the tested changes but does not authenticate
the coordinator, sign compiler provenance, stop new unauthorized registrations,
or enforce storage immutability. Receipt registration and state publication are
not one durability transaction, and no power-loss behavior is established. Source
and object paths, external interfaces, and the lock remain assumed stable between
checks and use. Post-validation mutation, hostile broker access, full external
runtime closure, retention/garbage collection, and deployed compiler integration
remain open. Controlled writes and restores affect only runner-owned fixtures.

The primary run records 38 observations: 23 added integration observations and
15 repeated closure prerequisites. It invokes 14 Gerbil commands, 13 completed
broker commands, and one deliberately killed publisher. The separate default
transaction regression records 45 observations.

See `31.24-native-closure-publication-integration.json` for the integration run,
its repeated closure prerequisites, and the separate 45-observation default
transaction regression. Earlier published observations remain historical evidence.


### Reader retention and owned generation collection

`publication_retention.py` adds a cooperating retention layer around the existing
registered-subject transaction. Acquisition reads the active subject, validates
it, and writes a unique persistent reader record under the same broker lock used
for publication and collection. A record binds reader ID, canonical load root,
publication epoch/digest, and receipt identity before any module load. Staging and
record writes use file/directory fsync; they are not a power-loss qualification.
Release requires the exact retained handle. Records have no TTL or PID-based expiry.

```sh
just audit-native-retention \
  /opt/homebrew/Cellar/gerbil-scheme@0.19/0.19.2591dcd.patchf5cedd8168cb/src/std/make.ss \
  t/native-build-recovery/installed-make.patch \
  /opt/homebrew/Cellar/gerbil-scheme@0.19/0.19.2591dcd.patchf5cedd8168cb/current/bin/gsc \
  /opt/homebrew/Cellar/gerbil-scheme@0.19/0.19.2591dcd.patchf5cedd8168cb/current/lib \
  /private/tmp/gerbil-reader-retention-study
```

The fixture declares its two exact owned generation roots. Collection must find
that root in the ownership registry, reject the active root, observe no reader
records for it, and require an independent writer-quiescence declaration. Unknown
reader files or malformed records conservatively block collection. After those
checks, collection marks the root retired and removes only that declared scratch
root. The cooperating publication callback rejects retired generations.

| Control | Observation |
|---------|-------------|
| Two A readers register before loading; B is published | B reader returns 43; collection of A exits 70 while A records exist |
| One A launcher is killed before it can exec Gerbil | Both records still retain A; process disappearance does not expire the record |
| Surviving A reader loads modules after B selection | Returns 42; after its explicit release, the killed launcher's record still blocks A collection |
| Explicitly release the owned killed pre-load launcher's record | Allowed only because this launcher was killed before exec and never created children; this is not generic dead-owner recovery |
| A has zero reader records but unknown writer quiescence | Collection exits 70 and retains A |
| A/B receive trusted fixture quiescence declarations | Active B still cannot be collected |
| A reader record is deliberately malformed in scratch storage | Collection exits 70; corruption is not treated as zero readers |
| A is inactive, unretained, and declared quiescent | Its owned root is collected and marked retired; later A publication is rejected without spending authority |
| A bare pin saved without retention is used after collection | Gerbil cannot find the app module and exits 70 |
| Retained selected B is read afterward | Returns 43; B storage and publication identity survive |

The quiescence flags are explicit trusted fixture-coordinator assertions after
successful native make completion and known owned producers, not proof inferred
from completion receipts, elapsed time, PID absence, or arbitrary detached jobs.
This study does not enforce the closing of a generation's writer capability.

Reader records are compared by canonical storage root, independently of their
receipt IDs or epochs. The delayed readers are fresh
Gerbil processes started after acquisition; one pauses before exec and imports
after B selection. This establishes retention before late module lookup, not
live module-cache switching, arbitrary cross-generation imports, or shared OS
storage confinement.

The layer assumes every participating publisher, reader, and collector uses this
protocol on stable paths. Registry/reader records and quiescence declarations are
not authenticated. Hostile writers, path replacement, interrupted acquisition or
release, collector crash/restart, and power loss are not qualified. Retirement
intent and directory removal are separate operations; interruption can leave
retired storage requiring an explicit recovery policy. Abandoned staging/reader
records block rather than authorize reclamation. External runtime dependencies
remain outside the application closure, and no deployed compiler behavior changes.

The run records 30 observations: 15 added retention observations and 15 repeated
closure prerequisites. It invokes 14 Gerbil commands, six collector commands, and
one deliberately killed Python reader launcher before exec.

See `31.25-native-reader-retention-study.json` for exact counts and observations.
The closure prerequisites are repeated in this run; prior integration and
transaction regression results are separate historical evidence.


### Interrupted reader records and resumable collection

`retention_crash.py` extends the retention control with acknowledged SIGKILL
checkpoints. The same fresh compiler closure supplies the native A/B bytes.
The previous retention study is separately rerun because release and collection
now support matching retries.

```sh
just audit-native-retention-crash \
  /opt/homebrew/Cellar/gerbil-scheme@0.19/0.19.2591dcd.patchf5cedd8168cb/src/std/make.ss \
  t/native-build-recovery/installed-make.patch \
  /opt/homebrew/Cellar/gerbil-scheme@0.19/0.19.2591dcd.patchf5cedd8168cb/current/bin/gsc \
  /opt/homebrew/Cellar/gerbil-scheme@0.19/0.19.2591dcd.patchf5cedd8168cb/current/lib \
  /private/tmp/gerbil-retention-crash-study
```

| Interrupted operation | Restart observation and recovery |
|-----------------------|----------------------------------|
| Acquire before staging | No reader record exists; the killed acquisition never returned a pin or launched a reader |
| Acquire after staging fsync | A pending record blocks collection as unrecognized reader state; only the owned pre-load fixture coordinator removes the exact verified record |
| Acquire after record installation or directory fsync | Persisted reader record blocks collection; exact-handle release is required |
| Release before release intent or after intent before unlink | Reader record still blocks collection; exact-handle retry completes release |
| Release after unlink or directory fsync | The exact release intent resolves matching retry as `ACK-RELEASE-REPLAY`; a changed handle is rejected |
| Collect after retirement intent | Root still exists and is fenced from publication; retry completes collection |
| Collect after first child deletion | Root exists with incomplete contents; retirement remains fenced and retry removes the remainder |
| Collect after root removal, before completion record | Missing root is consistent with recorded retirement; retry records completion |
| Collect after completion record, before acknowledgement | Retry returns `ACK-COLLECTION-REPLAY` |

Release persists a full-handle intent before unlinking the reader record. A retry
cannot treat a missing record as proof of success unless matching recorded intent
exists. Incorrect handle epochs are rejected at every tested release stage.
The release intent is an identity/recovery record, not proof that an arbitrary
reader has stopped using storage; the cooperative caller still owns that duty.

Collection records retired and collected as distinct states. Every retry checks
active selection, reader records, declared writer quiescence, and exact owned root
before progressing. The experiment revokes the quiescence flag after each kill;
resume refuses until the fixture coordinator declares it again. Retired A cannot
be published, authoritative publication bytes remain unchanged by collection,
and selected B imports as 43 after every recovery. If a collected root reappears,
collection refuses to delete it again instead of assuming it is the old storage.

The four collector checkpoint cases run sequentially. Between isolated cases,
the runner restores its original scratch A bytes from an owned backup only after
all owned operation processes ended and every reader record was released. This
is fixture setup, not a generation path recycling protocol. B is not reset.

Acquisition recovery is deliberately narrow: the killed operation did not return
or launch a reader and created no children. Staging cleanup verifies its exact
handle bytes under the broker lock. This is not generic orphan-reader recovery,
TTL expiry, or PID-based admission. In production, unknown readers or writers
still require independent trusted evidence and authority.

The host/filesystem remain running during SIGKILL. Release intent, reader record,
retirement registry, and physical directory removal are separate storage actions;
this control does not establish power-loss ordering, distributed filesystem
semantics, authenticated recovery, live reader termination, path immutability,
or writer-capability closure. Partial deletion is one explicit top-level child
checkpoint, not an exhaustive cut of every filesystem operation. Tombstone
retention and migration also remain open. Only owned scratch storage is mutated.

The primary run records 72 observations: 57 added recovery observations and 15
repeated closure prerequisites. It invokes 14 Gerbil commands, 30 completed
retention-operation commands, and 12 deliberately killed operation processes. The
separate baseline retention regression records 30 observations.

See `31.26-native-retention-process-crash-study.json` for current counts,
checkpoints, hashes, and the separate retention regression. Earlier publication
and transaction qualification counts are not added to this run.
