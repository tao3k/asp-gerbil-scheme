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

`installed-make.patch` was expanded with the official Gerbil MCP syntax checker
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
`tool-main-probe.ss` passes the official balance/syntax checks and returns 0 for
the positive fixture and 42 for the negative fixture. Its gxi/gxc branches are
unused probe stubs; this qualifies the gxtest branch, not a rebuilt Bach binary.
The full compiler patch has not been deployed.

The repository's Justfile and CI invoke `:gerbil/tools/gxtest` directly with an
explicit `exit` so they reject failed assertions on the current toolchain.
