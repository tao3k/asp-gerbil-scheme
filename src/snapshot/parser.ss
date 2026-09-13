;;; -*- Gerbil -*-
;;; Stable snapshot projections for native parser facts.

(import :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/snapshot/support
        (only-in :std/srfi/1 list-copy))

(export parser-source-file-snapshot)

;; : (-> Json Selector )
(def (parser-json-selector packet)
  (hash-get packet 'selector))

;;; Boundary:
;;; - parser-source-file-snapshot composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> SourceFile Snapshot )
(def (parser-source-file-snapshot file)
  (list 'parserSourceFile
        (list 'path (source-file-path file))
        (list 'definitions
              (map parser-definition-snapshot
                   (source-file-definitions file)))
        (list 'moduleImports
              (map parser-module-import-snapshot
                   (source-file-module-imports file)))
        (list 'moduleExports
              (map parser-module-export-snapshot
                   (source-file-module-exports file)))
        (list 'macros
              (map parser-macro-snapshot
                   (source-file-macros file)))
        (list 'bindings
              (map parser-binding-snapshot
                   (source-file-bindings file)))
        (list 'pooForms
              (map parser-poo-form-snapshot
                   (source-file-poo-forms file)))
        (list 'higherOrderForms
              (map parser-higher-order-form-snapshot
                   (source-file-higher-order-forms file)))
        (list 'controlFlowForms
              (map parser-control-flow-form-snapshot
                   (source-file-control-flow-forms file)))
        (list 'predicateFamilyFacts
              (map parser-predicate-family-fact-snapshot
                   (source-file-predicate-family-facts file)))
        (list 'fieldAccessPatternFacts
              (map parser-field-access-pattern-fact-snapshot
                   (source-file-field-access-pattern-facts file)))
        (list 'booleanConditionFacts
              (map parser-boolean-condition-fact-snapshot
                   (source-file-boolean-condition-facts file)))
        (list 'loopDriverFacts
              (map parser-loop-driver-fact-snapshot
                   (source-file-loop-driver-facts file)))
        (list 'functionQualityProfiles
              (map parser-function-quality-profile-snapshot
                   (source-file-function-quality-profiles file)))
        (list 'typedContractFacts
              (map parser-typed-contract-fact-snapshot
                   (source-file-typed-contract-facts file)))
        (list 'commentQualityFacts
              (map parser-comment-quality-fact-snapshot
                   (source-file-comment-quality-facts file)))
        (list 'calls
              (map parser-call-snapshot
                   (source-file-calls file)))))

;; : (-> Definition Snapshot )
(def (parser-definition-snapshot defn)
  (list 'definition
        (list 'name (definition-name defn))
        (list 'kind (definition-kind defn))
        (list 'formals (list-copy (definition-formals defn)))
        (list 'arity (definition-arity defn))
        (list 'selector (definition-selector defn))))

;; : (-> Fact Snapshot )
(def (parser-module-import-snapshot fact)
  (list 'moduleImport
        (list 'module (module-import-fact-module fact))
        (list 'phase (module-import-fact-phase fact))
        (list 'modifier (module-import-fact-modifier fact))
        (list 'symbols (list-copy (module-import-fact-symbols fact)))
        (list 'selector (module-import-fact-selector fact))))

;; : (-> Fact Snapshot )
(def (parser-module-export-snapshot fact)
  (list 'moduleExport
        (list 'name (module-export-fact-name fact))
        (list 'modifier (module-export-fact-modifier fact))
        (list 'alias (or (module-export-fact-alias fact) ""))
        (list 'module (or (module-export-fact-module fact) ""))
        (list 'symbols (list-copy (module-export-fact-symbols fact)))
        (list 'selector (module-export-fact-selector fact))))

;; : (-> Fact Snapshot )
(def (parser-macro-snapshot fact)
  (list 'macro
        (list 'name (macro-fact-name fact))
        (list 'kind (macro-fact-kind fact))
        (list 'transformer (macro-fact-transformer fact))
        (list 'phase (macro-fact-phase fact))
        (list 'patternCount (macro-fact-pattern-count fact))
        (list 'hygienicSyntax (macro-fact-hygienic fact))
        (list 'qualityFacets (list-copy (macro-fact-quality-facets fact)))
        (list 'selector (macro-fact-selector fact))))

;; : (-> Fact Snapshot )
(def (parser-binding-snapshot fact)
  (list 'binding
        (list 'name (binding-fact-name fact))
        (list 'kind (binding-fact-kind fact))
        (list 'scope (binding-fact-scope fact))
        (list 'valueType (or (binding-fact-value-type fact) "unknown"))
        (list 'selector (binding-fact-selector fact))))

;; : (-> Fact Snapshot )
(def (parser-poo-form-snapshot fact)
  (list 'pooForm
        (list 'name (poo-form-fact-name fact))
        (list 'kind (poo-form-fact-kind fact))
        (list 'role (poo-form-fact-role fact))
        (list 'generic (or (poo-form-fact-generic fact) ""))
        (list 'receiver (or (poo-form-fact-receiver fact) ""))
        (list 'receiverType (or (poo-form-fact-receiver-type fact) ""))
        (list 'supers (list-copy (poo-form-fact-supers fact)))
        (list 'slots (list-copy (poo-form-fact-slots fact)))
        (list 'options (list-copy (poo-form-fact-options fact)))
        (list 'specializers (list-copy (poo-form-fact-specializers fact)))
        (list 'specializerTypes (list-copy (poo-form-fact-specializer-types fact)))
        (list 'selector (poo-form-fact-selector fact))))

;; : (-> Fact Snapshot )
(def (parser-higher-order-form-snapshot fact)
  (list 'higherOrderForm
        (list 'name (higher-order-fact-name fact))
        (list 'kind (higher-order-fact-kind fact))
        (list 'role (higher-order-fact-role fact))
        (list 'operandCount (higher-order-fact-operand-count fact))
        (list 'arities (list-copy (higher-order-fact-arities fact)))
        (list 'formals (list-copy (higher-order-fact-formals fact)))
        (list 'caller (or (higher-order-fact-caller fact) ""))
        (list 'qualityFacets (list-copy (higher-order-quality-facets fact)))
        (list 'selector (higher-order-fact-selector fact))))

;; : (-> Fact Snapshot )
(def (parser-control-flow-form-snapshot fact)
  (list 'controlFlowForm
        (list 'name (control-flow-fact-name fact))
        (list 'kind (control-flow-fact-kind fact))
        (list 'role (control-flow-fact-role fact))
        (list 'caller (or (control-flow-fact-caller fact) ""))
        (list 'bindingCount (control-flow-fact-binding-count fact))
        (list 'bodyFormCount (control-flow-fact-body-form-count fact))
        (list 'qualityFacets (list-copy (control-flow-quality-facets fact)))
        (list 'selector (control-flow-fact-selector fact))))

;; : (-> PredicateFamilyFact Snapshot )
(def (parser-predicate-family-fact-snapshot fact)
  (list 'predicateFamilyFact
        (list 'name (predicate-family-fact-name fact))
        (list 'kind (predicate-family-fact-kind fact))
        (list 'role (predicate-family-fact-role fact))
        (list 'subject (predicate-family-fact-subject fact))
        (list 'predicateNames
              (list-copy (predicate-family-fact-predicate-names fact)))
        (list 'predicateCount (predicate-family-fact-predicate-count fact))
        (list 'fieldKeys (list-copy (predicate-family-fact-field-keys fact)))
        (list 'repeatedCallees
              (list-copy (predicate-family-fact-repeated-callees fact)))
        (list 'conditionCount (predicate-family-fact-condition-count fact))
        (list 'qualityFacets
              (list-copy (predicate-family-fact-quality-facets fact)))
        (list 'advice (predicate-family-fact-advice fact))
        (list 'selector (predicate-family-fact-selector fact))))

;; : (-> FieldAccessPatternFact Snapshot )
(def (parser-field-access-pattern-fact-snapshot fact)
  (list 'fieldAccessPatternFact
        (list 'name (field-access-pattern-fact-name fact))
        (list 'kind (field-access-pattern-fact-kind fact))
        (list 'role (field-access-pattern-fact-role fact))
        (list 'fieldKey (field-access-pattern-fact-field-key fact))
        (list 'callers (list-copy (field-access-pattern-fact-callers fact)))
        (list 'accessCount (field-access-pattern-fact-access-count fact))
        (list 'accessors (list-copy (field-access-pattern-fact-accessors fact)))
        (list 'qualityFacets
              (list-copy (field-access-pattern-fact-quality-facets fact)))
        (list 'advice (field-access-pattern-fact-advice fact))
        (list 'selector (field-access-pattern-fact-selector fact))))

;; : (-> BooleanConditionFact Snapshot )
(def (parser-boolean-condition-fact-snapshot fact)
  (list 'booleanConditionFact
        (list 'name (boolean-condition-fact-name fact))
        (list 'kind (boolean-condition-fact-kind fact))
        (list 'role (boolean-condition-fact-role fact))
        (list 'caller (boolean-condition-fact-caller fact))
        (list 'formals (list-copy (boolean-condition-fact-formals fact)))
        (list 'conditionCallees
              (list-copy (boolean-condition-fact-condition-callees fact)))
        (list 'fieldKeys (list-copy (boolean-condition-fact-field-keys fact)))
        (list 'conditionCount (boolean-condition-fact-condition-count fact))
        (list 'qualityFacets
              (list-copy (boolean-condition-fact-quality-facets fact)))
        (list 'advice (boolean-condition-fact-advice fact))
        (list 'selector (boolean-condition-fact-selector fact))))

;; : (-> LoopDriverFact Snapshot )
(def (parser-loop-driver-fact-snapshot fact)
  (list 'loopDriverFact
        (list 'name (loop-driver-fact-name fact))
        (list 'kind (loop-driver-fact-kind fact))
        (list 'role (loop-driver-fact-role fact))
        (list 'caller (loop-driver-fact-caller fact))
        (list 'driverKind (loop-driver-fact-driver-kind fact))
        (list 'bindingCount (loop-driver-fact-binding-count fact))
        (list 'bodyFormCount (loop-driver-fact-body-form-count fact))
        (list 'qualityFacets
              (list-copy (loop-driver-fact-quality-facets fact)))
        (list 'advice (loop-driver-fact-advice fact))
        (list 'selector (loop-driver-fact-selector fact))))

;;; Snapshot projection fixes profile field order for reviewable fixtures.
;;; It preserves the same repair signals emitted to JSON so snapshot drift shows
;;; real parser-evidence changes, not hash-table ordering.
;; : (-> FunctionQualityProfile Snapshot )
(def (parser-function-quality-profile-snapshot profile)
  (list 'functionQualityProfile
        (list 'name (function-quality-profile-name profile))
        (list 'kind (function-quality-profile-kind profile))
        (list 'role (function-quality-profile-role profile))
        (list 'exported (function-quality-profile-exported profile))
        (list 'formals
              (list-copy (function-quality-profile-formals profile)))
        (list 'arity (function-quality-profile-arity profile))
        (list 'typedContractQuality
              (function-quality-profile-typed-contract-quality profile))
        (list 'commentQuality
              (function-quality-profile-comment-quality profile))
        (list 'controlFlowRoles
              (list-copy
               (function-quality-profile-control-flow-roles profile)))
        (list 'higherOrderRoles
              (list-copy
               (function-quality-profile-higher-order-roles profile)))
        (list 'predicateFamilyRefs
              (list-copy
               (function-quality-profile-predicate-family-refs profile)))
        (list 'fieldAccessPatternRefs
              (list-copy
               (function-quality-profile-field-access-pattern-refs profile)))
        (list 'loopDriverRefs
              (list-copy
               (function-quality-profile-loop-driver-refs profile)))
        (list 'macroRefs
              (list-copy (function-quality-profile-macro-refs profile)))
        (list 'pooProtocolRefs
              (list-copy
               (function-quality-profile-poo-protocol-refs profile)))
        (list 'qualityFacets
              (list-copy
               (function-quality-profile-quality-facets profile)))
        (list 'preservationReasons
              (list-copy
               (function-quality-profile-preservation-reasons profile)))
        (list 'suggestedRepairClass
              (function-quality-profile-suggested-repair-class profile))
        (list 'parserConfidence
              (function-quality-profile-parser-confidence profile))
        (list 'advice (function-quality-profile-advice profile))
        (list 'selector (function-quality-profile-selector profile))))

;; : (-> TypedContractFact Snapshot )
(def (parser-typed-contract-fact-snapshot fact)
  (list 'typedContractFact
        (list 'definition (typed-contract-fact-definition-name fact))
        (list 'definitionKind (typed-contract-fact-definition-kind fact))
        (list 'definitionFormals (list-copy (typed-contract-fact-definition-formals fact)))
        (list 'definitionArity (typed-contract-fact-definition-arity fact))
        (list 'contract (typed-contract-fact-contract fact))
        (list 'contractOutput (typed-contract-fact-contract-output fact))
        (list 'contractInputs (list-copy (typed-contract-fact-contract-inputs fact)))
        (list 'contractInputCount (typed-contract-fact-contract-input-count fact))
        (list 'arityAlignment (typed-contract-fact-arity-alignment fact))
        (list 'tokens (list-copy (typed-contract-fact-tokens fact)))
        (list 'quality (typed-contract-fact-quality fact))
        (list 'reasons (list-copy (typed-contract-fact-reasons fact)))
        (list 'qualityFacets (list-copy (typed-contract-fact-quality-facets fact)))
        (list 'repairEvidence
              (parser-typed-contract-repair-evidence-snapshot
               (typed-contract-fact-repair-evidence fact)))
        (list 'arrowCount (typed-contract-fact-arrow-count fact))
        (list 'groupCount (typed-contract-fact-group-count fact))
        (list 'selector (typed-contract-fact-selector fact))))

;;; Repair evidence snapshots turn parser-owned hash packets into reader-safe data.
;;; Keep advice fields visible without leaking opaque table tokens into fixtures.
;; : (-> Json Snapshot )
(def (parser-typed-contract-repair-evidence-snapshot evidence)
  (list 'repairEvidence
        (list 'factSource (hash-get evidence 'factSource))
        (list 'trigger (hash-get evidence 'trigger))
        (list 'definition (hash-get evidence 'definition))
        (list 'definitionKind (hash-get evidence 'definitionKind))
        (list 'definitionFormals
              (list-copy (hash-get evidence 'definitionFormals)))
        (list 'definitionArity (hash-get evidence 'definitionArity))
        (list 'path (hash-get evidence 'path))
        (list 'lineSpan (list-copy (hash-get evidence 'lineSpan)))
        (list 'selector (parser-json-selector evidence))
        (list 'contract (hash-get evidence 'contract))
        (list 'quality (hash-get evidence 'quality))
        (list 'qualityFacets
              (list-copy (hash-get evidence 'qualityFacets)))
        (list 'matchedCalls
              (map parser-repair-call-snapshot
                   (hash-get evidence 'matchedCalls)))
        (list 'matchedHigherOrder
              (map parser-repair-higher-order-snapshot
                   (hash-get evidence 'matchedHigherOrder)))
        (list 'matchedControlFlow
              (map parser-repair-control-flow-snapshot
                   (hash-get evidence 'matchedControlFlow)))
        (list 'allowedMoves
              (list-copy (hash-get evidence 'allowedMoves)))
        (list 'forbiddenMoves
              (list-copy (hash-get evidence 'forbiddenMoves)))
        (list 'witnessNeeded
              (list-copy (hash-get evidence 'witnessNeeded)))
        (list 'agentRepairMode (hash-get evidence 'agentRepairMode))))

;; : (-> Json Snapshot )
(def (parser-repair-call-snapshot evidence)
  (list 'repairCall
        (list 'kind (hash-get evidence 'kind))
        (list 'name (hash-get evidence 'name))
        (list 'arity (hash-get evidence 'arity))
        (list 'selector (parser-json-selector evidence))))

;; : (-> Json Snapshot )
(def (parser-repair-higher-order-snapshot evidence)
  (list 'repairHigherOrder
        (list 'kind (hash-get evidence 'kind))
        (list 'name (hash-get evidence 'name))
        (list 'role (hash-get evidence 'role))
        (list 'operandCount (hash-get evidence 'operandCount))
        (list 'selector (parser-json-selector evidence))))

;; : (-> Json Snapshot )
(def (parser-repair-control-flow-snapshot evidence)
  (list 'repairControlFlow
        (list 'kind (hash-get evidence 'kind))
        (list 'name (hash-get evidence 'name))
        (list 'role (hash-get evidence 'role))
        (list 'bindingCount (hash-get evidence 'bindingCount))
        (list 'bodyFormCount (hash-get evidence 'bodyFormCount))
        (list 'selector (parser-json-selector evidence))))

;; : (-> CommentQualityFact Snapshot )
(def (parser-comment-quality-fact-snapshot fact)
  (list 'commentQualityFact
        (list 'targetKind (comment-quality-fact-target-kind fact))
        (list 'targetName (comment-quality-fact-target-name fact))
        (list 'context (comment-quality-fact-context fact))
        (list 'commentKind (comment-quality-fact-comment-kind fact))
        (list 'quality (comment-quality-fact-quality fact))
        (list 'required (comment-quality-fact-required fact))
        (list 'reasons (list-copy (comment-quality-fact-reasons fact)))
        (list 'commentLines (list-copy (comment-quality-fact-comment-lines fact)))
        (list 'targetStart (comment-quality-fact-target-start fact))
        (list 'targetEnd (comment-quality-fact-target-end fact))
        (list 'parserEvidence
              (parser-comment-quality-evidence-snapshot
               (comment-quality-fact-evidence fact)))
        (list 'selector (comment-quality-fact-selector fact))))

;;; Snapshot boundary: serialize comment evidence in fixed field order so parser fact changes are reviewable across runs.
;; : (-> Json Snapshot )
(def (parser-comment-quality-evidence-snapshot evidence)
  (let (target-kind (hash-get evidence 'targetKind))
    (if (equal? target-kind "module")
      (list 'commentEvidence
            (list 'factSource (hash-get evidence 'factSource))
            (list 'targetKind target-kind)
            (list 'path (hash-get evidence 'path))
            (list 'lineCount (hash-get evidence 'lineCount))
            (list 'existingCommentLineCount
                  (hash-get evidence 'existingCommentLineCount))
            (list 'commentFocus (hash-get evidence 'commentFocus))
            (list 'commentQuestions
                  (list-copy (hash-get evidence 'commentQuestions)))
            (list 'agentRepairMode (hash-get evidence 'agentRepairMode)))
      (list 'commentEvidence
            (list 'factSource (hash-get evidence 'factSource))
            (list 'targetKind target-kind)
            (list 'definition (hash-get evidence 'definition))
            (list 'definitionKind (hash-get evidence 'definitionKind))
            (list 'definitionFormals
                  (list-copy (hash-get evidence 'definitionFormals)))
            (list 'definitionArity (hash-get evidence 'definitionArity))
            (list 'lineSpan (hash-get evidence 'lineSpan))
            (list 'context (hash-get evidence 'context))
            (list 'existingCommentLineCount
                  (hash-get evidence 'existingCommentLineCount))
            (list 'matchedFactCount (hash-get evidence 'matchedFactCount))
            (list 'matchedFacts
                  (map parser-comment-quality-matched-fact-snapshot
                       (hash-get evidence 'matchedFacts)))
            (list 'commentFocus (hash-get evidence 'commentFocus))
            (list 'commentQuestions
                  (list-copy (hash-get evidence 'commentQuestions)))
            (list 'agentRepairMode (hash-get evidence 'agentRepairMode))
            (list 'selector (parser-json-selector evidence))))))

;;; Matched fact snapshots mirror evidence variants while preserving type-specific witness fields and deterministic output order.
;; : (-> Json Snapshot )
(def (parser-comment-quality-matched-fact-snapshot fact)
  (let (fact-kind (hash-get fact 'factKind))
    (cond
     ((equal? fact-kind "macro")
      (list 'matchedFact
            (list 'factKind fact-kind)
            (list 'name (hash-get fact 'name))
            (list 'formKind (hash-get fact 'formKind))
            (list 'transformer (hash-get fact 'transformer))
            (list 'phase (hash-get fact 'phase))
            (list 'patternCount (hash-get fact 'patternCount))
            (list 'hygienicSyntax (hash-get fact 'hygienicSyntax))
            (list 'qualityFacets
                  (list-copy (hash-get fact 'qualityFacets)))
            (list 'selector (parser-json-selector fact))))
     ((equal? fact-kind "poo")
      (list 'matchedFact
            (list 'factKind fact-kind)
            (list 'name (hash-get fact 'name))
            (list 'formKind (hash-get fact 'formKind))
            (list 'role (hash-get fact 'role))
            (list 'generic (hash-get fact 'generic))
            (list 'receiver (hash-get fact 'receiver))
            (list 'receiverType (hash-get fact 'receiverType))
            (list 'supers (list-copy (hash-get fact 'supers)))
            (list 'slots (list-copy (hash-get fact 'slots)))
            (list 'specializers (list-copy (hash-get fact 'specializers)))
            (list 'specializerTypes
                  (list-copy (hash-get fact 'specializerTypes)))
            (list 'selector (parser-json-selector fact))))
     ((equal? fact-kind "higher-order")
      (list 'matchedFact
            (list 'factKind fact-kind)
            (list 'name (hash-get fact 'name))
            (list 'formKind (hash-get fact 'formKind))
            (list 'role (hash-get fact 'role))
            (list 'operandCount (hash-get fact 'operandCount))
            (list 'arities (list-copy (hash-get fact 'arities)))
            (list 'formals (list-copy (hash-get fact 'formals)))
            (list 'caller (hash-get fact 'caller))
            (list 'selector (parser-json-selector fact))))
     (else
      (list 'matchedFact
            (list 'factKind fact-kind)
            (list 'name (hash-get fact 'name))
            (list 'formKind (hash-get fact 'formKind))
            (list 'role (hash-get fact 'role))
            (list 'caller (hash-get fact 'caller))
            (list 'bindingCount (hash-get fact 'bindingCount))
            (list 'bodyFormCount (hash-get fact 'bodyFormCount))
            (list 'selector (parser-json-selector fact)))))))
;;; Boundary:
;;; - parser-call-snapshot composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> Fact Snapshot )
(def (parser-call-snapshot fact)
  (list 'call
        (list 'callee (call-fact-callee fact))
        (list 'arity (call-fact-arity fact))
        (list 'caller (or (call-fact-caller fact) ""))
        (list 'arguments (list-copy (call-fact-arguments fact)))
        (list 'argumentTypes
              (list-copy
               (map (lambda (type) (or type "unknown"))
                    (call-fact-argument-types fact))))
        (list 'selector (call-fact-selector fact))))
