;;; -*- Gerbil -*-
(import :clan/poo/object)

(def (marlinRealRepair001LoopProgramCompilerReceipt)
  (.o receipt-id: "real-repair-001"
      compiler: "asp-gerbil-scheme"
      status: 'accepted))

(def (marlinRealRepair002LoopProgramCompilerReceipt)
  (.o receipt-id: "real-repair-002"
      compiler: "asp-gerbil-scheme"
      status: 'accepted))

(def (marlinRealRepair003LoopProgramCompilerReceipt)
  (.o receipt-id: "real-repair-003"
      compiler: "asp-gerbil-scheme"
      status: 'accepted))

(def (user-interface-contract-field contract key)
  (.get contract key))

(def (user-interface-workspace-root config)
  (.get config workspace-root))

(def (marlinDefaultLoopEngineReceiptContracts)
  (vector
   (.o id: "loop-receipt"
       schema: "marlin.loop.receipt.v1")
   (.o id: "handoff-receipt"
       schema: "marlin.loop.handoff.v1")))

(def +projection-specs+
  `(("poo-flow.loop-engine.real-repair-001"
     "real-repair-001/reactive-tool-loop"
     "loop-engine"
     ,(vector "fun-flow" "loop-engine" "sandbox" "tool-handoff")
     "real-repair-001"
     ,(vector '+scripted-e2e '+tool-repair '+verification)
     ,(marlinRealRepair001LoopProgramCompilerReceipt))
    ("poo-flow.loop-engine.real-repair-002"
     "real-repair-002/reactive-tool-loop"
     "loop-engine"
     ,(vector "fun-flow" "loop-engine" "sandbox" "tool-handoff")
     "real-repair-002"
     ,(vector '+scripted-e2e '+tool-repair '+verification)
     ,(marlinRealRepair002LoopProgramCompilerReceipt))
    ("poo-flow.loop-engine.real-repair-003"
     "real-repair-003/reactive-tool-loop"
     "loop-engine"
     ,(vector "fun-flow" "loop-engine" "sandbox" "tool-handoff")
     "real-repair-003"
     ,(vector '+scripted-e2e '+tool-repair '+verification)
     ,(marlinRealRepair003LoopProgramCompilerReceipt))))

(def marlinLoopPolicyProfileProjectionDescriptor
  (lambda-match
    ([module-id-value
      profile-id-value
      poo-flow-module-value
      capability-lanes-value
      vertical-case-id-value
      vertical-capability-tags-value
      compiler-receipt-value]
     (.o kind: "marlin.config-interface.loop-policy.profile-projection-module.v1"
         module-id: module-id-value
         profile-id: profile-id-value
         poo-flow-module: poo-flow-module-value
         poo-flow-capability-lanes: capability-lanes-value
         vertical-case-id: vertical-case-id-value
         vertical-capability-tags: vertical-capability-tags-value
         vertical-mainline?: (and vertical-case-id-value #t)
         compiler-receipt: compiler-receipt-value))))

(def (marlinLoopPolicyProfileProjectionDescriptors)
  (list->vector
   (map marlinLoopPolicyProfileProjectionDescriptor
        +projection-specs+)))

(def (UserInterfaceMarlinLoopsPolicy config)
  (let* ((workspace-root-value (user-interface-workspace-root config))
         (receipt-contracts-value
          (marlinDefaultLoopEngineReceiptContracts))
         (receipt-family-ids
          (map (lambda (contract)
                 (user-interface-contract-field contract 'id))
               receipt-contracts-value))
         (receipt-schema-ids
          (map (lambda (contract)
                 (user-interface-contract-field contract 'schema))
               receipt-contracts-value)))
    (.o kind: "marlin.config-interface.user-interface.loops-policy.v1"
        id: "user-interface-marlin-loops-policy"
        owner: "marlin"
        source: "config-interface/modules/prefabs/user-interface#loops-policy"
        reference-role: "marlin-owned-loops-policy"
        upstream-example-role: "poo-flow-user-interface-reference-only"
        control-plane-owner: "poo-flow"
        runtime-execution-owner: "marlin-agent-core"
        runtime-effect: "handoff-only"
        loop-name: 'user-interface-policy-loop
        governor-id: 'user-interface-policy-governor
        strategy-id: 'user-interface-policy-strategy
        summary:
        "Report user-interface policy handoff readiness for Marlin runtime."
        level: 'l2
        priority: 1
        workspace-root: workspace-root-value
        budget: '((max-attempts . 1) (max-actionable . 1))
        isolation: '((mode . workspace))
        maker: '((enabled . #f))
        checker: '((required . #t))
        capabilities: '(+manifest-handoff +l1-receipts)
        open-patterns: '(user-interface-policy-loop)
        blocked-patterns: '()
        receipt-contracts: receipt-contracts-value
        receipt-family-ids: receipt-family-ids
        receipt-schema-ids: receipt-schema-ids)))

(def (policy-metadata workspace-root-value source-value control-plane-owner-value
                      owner-value)
  `((acting_on . ,workspace-root-value)
    (source . ,source-value)
    (module-system . ,control-plane-owner-value)
    (policy-owner . ,owner-value)))

(def (UserInterfaceLoopGovernorPattern config)
  (let (loops-policy (UserInterfaceMarlinLoopsPolicy config))
    (match loops-policy
      ((.o loop-name: loop-name-value
           summary: summary-value
           workspace-root: workspace-root-value
           budget: budget-value
           isolation: isolation-value
           maker: maker-value
           checker: checker-value
           level: level-value
           priority: priority-value
           source: source-value
           control-plane-owner: control-plane-owner-value
           owner: owner-value)
       (make-loop-pattern-descriptor
        loop-name-value
        summary-value
        `((level . ,level-value)
          (priority . ,priority-value)
          (watched-scope . (,workspace-root-value))
          (budget . ,budget-value)
          (isolation . ,isolation-value)
          (maker . ,maker-value)
          (checker . ,checker-value)
          (metadata .
                    ,(policy-metadata workspace-root-value source-value
                                      control-plane-owner-value
                                      owner-value))))))))
