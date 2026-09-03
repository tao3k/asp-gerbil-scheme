;;; Public module wrapper for the source-bootstrapped Build SS bridge.  The
;;; implementation projects declarations, profiles, host capabilities, and
;;; observations onto one upstream std/make session. Core admission synchronizes
;;; the selected host value with Gerbil 0.18.2's captured compiler counter; the
;;; Framework does not own dependency ordering, freshness, or job scheduling.
(include "build-script-body.inc")

(export defbuild-script
        framework-build-artifact-root
        framework-build-bindir
        framework-executable-build-spec
        framework-validate-runtime-closure!
        framework-build-cache-root
        framework-build-core-count
        framework-build-trace-receipt
        framework-apply-build-core-policy!
        framework-build-profile-options
        framework-parse-build-options
        framework-resolve-build-keys
        framework-normalize-build-options
        framework-merge-build-options
        framework-recover-object-locks!
        call-with-framework-native-toolchain-environment
        call-with-framework-build-lease
        framework-build-contract)
