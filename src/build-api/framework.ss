;;; Boundary: the package-facing Build API re-exports the Building Framework POO model.
;;; Invariant: this facade preserves pure stage planning; package receipt persistence stays in Build API owners.
(import ../building/facade
        ../building/package-spec
        :asp-gerbil-scheme/src/building/commands)

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
        default-std-builder
        std-builder-effective-options
        std-builder-run-spec!
        std-builder-clean-spec!
        std-builder-stage
        build-request-clean!
        build-requests-run!
        build-requests-clean!
        package-source-stage
        package-source-stage?
        make-package-source-stage
        package-source-stage-label
        package-source-stage-source
        package-source-stage-prefix
        package-source-stage-specs
        package-source-stage-batched?
        package-source-stage-current?
        source-topology-layers
        source-topology-affected
        package-source-stage-dependencies
        package-source-stage-topology-layers
        package-source-stage->request
        package-source-stages->requests
        package-source-stages-spec
        package-source-stages-run!
        package-source-stages-clean!
        (import: ../building/package-spec)
        (import: :asp-gerbil-scheme/src/building/commands))
