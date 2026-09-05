;;; -*- Gerbil -*-
(import :clan/poo/object)

(def (marlin-policy-object<-alist rows)
  (object<-alist rows))

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

(def (marlinLoopPolicyProfileProjectionDescriptor module-id-value
                                                   profile-id-value
                                                   poo-flow-module-value
                                                   capability-lanes-value
                                                   vertical-case-id-value
                                                   vertical-capability-tags-value
                                                   compiler-receipt-value)
  (marlin-policy-object<-alist
   (list
    (cons 'kind "marlin.config-interface.loop-policy.profile-projection-module.v1")
    (cons 'module-id module-id-value)
    (cons 'profile-id profile-id-value)
    (cons 'poo-flow-module poo-flow-module-value)
    (cons 'poo-flow-capability-lanes capability-lanes-value)
    (cons 'vertical-case-id vertical-case-id-value)
    (cons 'vertical-capability-tags vertical-capability-tags-value)
    (cons 'vertical-mainline? (if vertical-case-id-value #t #f))
    (cons 'compiler-receipt compiler-receipt-value))))

(def (marlinLoopPolicyProfileProjectionDescriptors)
  (vector
   (marlinLoopPolicyProfileProjectionDescriptor
    "poo-flow.loop-engine.real-repair-001"
    "real-repair-001/reactive-tool-loop"
    "loop-engine"
    (vector "fun-flow" "loop-engine" "sandbox" "tool-handoff")
    "real-repair-001"
    (vector '+scripted-e2e '+tool-repair '+verification)
    (marlinRealRepair001LoopProgramCompilerReceipt))
   (marlinLoopPolicyProfileProjectionDescriptor
    "poo-flow.loop-engine.real-repair-002"
    "real-repair-002/reactive-tool-loop"
    "loop-engine"
    (vector "fun-flow" "loop-engine" "sandbox" "tool-handoff")
    "real-repair-002"
    (vector '+scripted-e2e '+tool-repair '+verification)
    (marlinRealRepair002LoopProgramCompilerReceipt))
   (marlinLoopPolicyProfileProjectionDescriptor
    "poo-flow.loop-engine.real-repair-003"
    "real-repair-003/reactive-tool-loop"
    "loop-engine"
    (vector "fun-flow" "loop-engine" "sandbox" "tool-handoff")
    "real-repair-003"
    (vector '+scripted-e2e '+tool-repair '+verification)
    (marlinRealRepair003LoopProgramCompilerReceipt))))

(def (UserInterfaceMarlinLoopsPolicy config)
  (let ((workspace-root-value (user-interface-workspace-root config))
        (receipt-contracts-value
         (marlinDefaultLoopEngineReceiptContracts)))
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
        receipt-family-ids:
        (map (lambda (contract)
               (user-interface-contract-field contract 'id))
             receipt-contracts-value)
        receipt-schema-ids:
        (map (lambda (contract)
               (user-interface-contract-field contract 'schema))
             receipt-contracts-value))))

(def (UserInterfaceLoopGovernorPattern config)
  (let (loops-policy (UserInterfaceMarlinLoopsPolicy config))
    (make-loop-pattern-descriptor
     (.get loops-policy loop-name)
     (.get loops-policy summary)
     (list (cons 'level (.get loops-policy level))
           (cons 'priority (.get loops-policy priority))
           (cons 'watched-scope
                 (list (.get loops-policy workspace-root)))
           (cons 'budget (.get loops-policy budget))
           (cons 'isolation (.get loops-policy isolation))
           (cons 'maker (.get loops-policy maker))
           (cons 'checker (.get loops-policy checker))
           (cons 'metadata
                 (list (cons 'acting_on
                             (.get loops-policy workspace-root))
                       (cons 'source
                             (.get loops-policy source))
                       (cons 'module-system
                             (.get loops-policy control-plane-owner))
                       (cons 'policy-owner
                             (.get loops-policy owner))))))))
