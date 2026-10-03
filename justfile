set shell := ["bash", "-euo", "pipefail", "-c"]
set positional-arguments

# Homebrew Gerbil/Gambit must use the host macOS SDK.  A surrounding Nix
# environment may inject its own Apple SDK and break Gambit's C compilation.
# Other platforms retain their native Gerbil environment unchanged.
logical_cores := `getconf _NPROCESSORS_ONLN`
build_cores := env_var_or_default("GERBIL_BUILD_CORES", logical_cores)
gerbil := if os() == "macos" {
    "env -u SDKROOT -u DEVELOPER_DIR GERBIL_BUILD_CORES=" + build_cores + " gerbil"
} else {
    "env GERBIL_BUILD_CORES=" + build_cores + " gerbil"
}
gxi := if os() == "macos" {
    "env -u SDKROOT -u DEVELOPER_DIR GERBIL_BUILD_CORES=" + build_cores + " gxi"
} else {
    "env GERBIL_BUILD_CORES=" + build_cores + " gxi"
}
# Propagate the upstream result explicitly: this installed Bach dispatcher can
# return exit 0 even when gxtest reports a failed assertion.
gxtest_exit := "(import :gerbil/tools/gxtest) (exit (apply main (cdddr (command-line))))"

default:
    @just --list

# Native package lifecycle; no private command dispatch or artifact handling.
deps:
    {{gerbil}} deps --install

clean:
    {{gerbil}} clean

build:
    {{gerbil}} build

check-policy:
    ASP_GERBIL_SCHEME_POLICY=1 {{gerbil}} build

test:
    {{gxi}} -e '{{gxtest_exit}}' t/support-list-test.ss t/build-script-command-test.ss t/package-build-contract-test.ss t/package-native-declaration-test.ss t/native-import-public-closure-scenario-test.ss t/build-api-source-bootstrap-test.ss t/build-api-policy-projection-test.ss t/build-api-startup-scenario-test.ss t/provider-owned-schema-registry-test.ss t/exact-source-projection-test.ss t/projection-batch-test.ss t/projection-batch-scenario-test.ss t/language-projection-test.ss t/testing-extension-test.ss t/testing-native-batch-scenario-test.ss t/policy/agent-dependency-adapter-test.ss t/project-policy-test.ss

test-files +files:
    {{gxi}} -e '{{gxtest_exit}}' "$@"

# Isolated compiler regression; supply the exact std/make source and patch base.
audit-native-recovery make_source patch output:
    python3 t/native-build-recovery/run.py --make-source "$1" --patch "$2" --output "$3"

# Isolated compiler qualification; the lease mode remains experimental.
audit-native-frontend make_source patch native_gsc output:
    python3 t/native-build-recovery/frontend.py --make-source "$1" --patch "$2" --native-gsc "$3" --output "$4/worker" --qualify
    python3 t/native-build-recovery/frontend.py --make-source "$1" --patch "$2" --native-gsc "$3" --output "$4/secondary" --qualify --fail-backend
    python3 t/native-build-recovery/frontend.py --make-source "$1" --patch "$2" --native-gsc "$3" --output "$4/coordinator" --qualify --coordinator-fault
    python3 t/native-build-recovery/frontend.py --make-source "$1" --patch "$2" --native-gsc "$3" --output "$4/lease" --qualify --experimental-lease --fail-backend

# Research controls only: no production recovery or generation publication.
audit-native-namespace make_source patch native_gsc output:
    python3 t/native-build-recovery/namespace.py --make-source "$1" --patch "$2" --native-gsc "$3" --output "$4"

clean-provider:
    {{gerbil}} env gerbil interactive build-provider.ss clean

build-provider:
    {{gerbil}} env gerbil interactive build-provider.ss compile

check: check-policy test

# Keep the cold lifecycle sequential and fail on its first error.
rebuild:
    just clean
    just deps
    just build
    just test
