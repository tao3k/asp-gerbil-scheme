;;; Boundary: this facade is the only downstream import surface for Building values.
;;; It keeps profile/request composition independent of package scripts and loaders.
;;; Invariant: std/make owns dependency topology, currentness, and scheduling;
;;; package receipt persistence remains in Build API.
(import ./model
        ./std-builder
        ./native-toolchain)

(export build-stage
        build-stage?
        make-build-stage
        build-stage-label
        build-stage-kind
        build-stage-spec
        build-stage-current-pred
        build-stage-runner
        build-stage-after
        build-stage-description
        build-stage-receipt
        build-stage-receipt?
        make-build-stage-receipt
        build-stage-receipt-label
        build-stage-receipt-kind
        build-stage-receipt-status
        build-stage-receipt-description
        build-stage-receipt-result
        build-stage-receipt-elapsed-jiffies
        build-stage-receipt->alist
        build-plan-receipts->alist
        build-plan-receipts-summary
        build-stage-status
        build-stage-run!
        build-plan-run!
        std-builder
        std-builder?
        make-std-builder
        std-builder-name
        std-builder-make-proc
        std-builder-stage-kind
        std-builder-description
        std-builder-srcdir
        std-builder-make-options
        std-builder-toolchain
        default-std-builder
        std-builder-effective-options
        std-builder-run-spec!
        std-builder-clean-spec!
        std-builder-stage)
(export std-builder-stage-plan
        make-build-profile
        build-profile?
        build-profile-name
        build-profile-builder
        build-profile-label-of
        build-profile-extra-options
        build-profile-after
        build-profile-description
        make-build-request
        build-request?
        build-request-label
        build-request-profile
        build-request-stage-specs
        build-request-current-pred
        build-request-context
        make-std-builder-profile
        make-std-builder-request
        build-request-stage-plan
        build-request-run!
        build-request-clean!
        build-requests-run!
        build-requests-clean!
        build-request->alist
        native-toolchain
        native-toolchain?
        make-native-toolchain
        native-toolchain-sdkroot
        native-toolchain-developer-dir
        native-toolchain-compiler-path
        native-toolchain-toolchain-kind
        native-toolchain-sdk-kind
        native-toolchain-default
        with-native-toolchain)
(export package-source-stage
        package-source-stage?
        make-package-source-stage
        package-source-stage-label
        package-source-stage-source
        package-source-stage-prefix
        package-source-stage-specs
        package-source-stage-batched?
        package-source-stage->request
        package-source-stages->requests
        package-source-stages-spec
        package-source-stages-run!
        package-source-stages-clean!)
;; Building facade owns public stage plans and receipt projections; native policy remains upstream.
(import ./observability
        ./memory-anomaly-guard)
(export (import: ./observability))
(export (import: ./memory-anomaly-guard))
