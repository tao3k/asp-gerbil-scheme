;;; Public module wrapper for the source-bootstrapped Build SS bridge.
(include "build-script-body.inc")

(export defbuild-script
        framework-build-artifact-root
        framework-build-bindir
        framework-executable-build-spec
        framework-validate-runtime-closure!
        framework-build-cache-root
        framework-build-core-count
        framework-build-reexec-required?
        framework-reexec-build-script
        call-with-framework-build-cores
        framework-recover-object-locks!
        call-with-framework-build-lease
        framework-build-contract)
