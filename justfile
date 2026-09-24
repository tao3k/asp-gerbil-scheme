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

default:
    @just --list

# Native package lifecycle; no private command dispatch or artifact handling.
deps:
    {{gerbil}} deps --install

clean:
    {{gerbil}} clean

build:
    {{gerbil}} build

test:
    {{gerbil}} test t/support-list-test.ss t/build-script-command-test.ss t/package-build-contract-test.ss t/package-native-declaration-test.ss t/native-import-public-closure-scenario-test.ss t/build-api-source-bootstrap-test.ss t/build-api-startup-scenario-test.ss t/provider-owned-schema-registry-test.ss t/exact-source-projection-test.ss t/projection-batch-test.ss t/projection-batch-scenario-test.ss t/language-projection-test.ss t/testing-extension-test.ss t/testing-native-batch-scenario-test.ss t/project-policy-test.ss

test-files +files:
    {{gerbil}} test "$@"

clean-provider:
    {{gerbil}} env gerbil interactive build-provider.ss clean

build-provider:
    {{gerbil}} env gerbil interactive build-provider.ss compile

check: build test

# Keep the cold lifecycle sequential and fail on its first error.
rebuild:
    just clean
    just deps
    just build
    just test
