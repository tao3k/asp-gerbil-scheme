;;; Public module wrapper for the source-bootstrapped Build SS bridge.  The
;;; implementation projects declarations, profiles, host capabilities, and
;;; observations onto one upstream std/make session; it does not own Gerbil's
;;; dependency graph, freshness decisions, or compiler scheduling.
(include "build-script-body.inc")

(export defbuild-script
        framework-build-artifact-root
        framework-build-bindir
        framework-executable-build-spec
        framework-validate-runtime-closure!
        framework-build-cache-root
        framework-build-core-count
        framework-build-profile-options
        framework-resolve-build-keys
        framework-normalize-build-options
        framework-merge-build-options
        framework-build-reexec-required?
        framework-reexec-build-script
        framework-recover-object-locks!
        call-with-framework-native-toolchain-environment
        call-with-framework-build-lease
        framework-build-contract)
