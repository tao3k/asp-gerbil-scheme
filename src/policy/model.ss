;;; -*- Gerbil -*-
;;; Boundary:
;;; - module owns an agent-facing surface.
;;; - Keep contracts, evidence, and failure semantics explicit.
;;; Native policy rule model.

(export make-policy-rule
        policy-rule-id
        policy-rule-severity
        +modularity-facade-rule+
        +modularity-source-leaf-rule+
        +modularity-owner-collision-rule+
        +modularity-repeated-owner-entry-rule+
        +modularity-bin-entrypoint-rule+
        +modularity-test-directory-rule+
        +modularity-test-leaf-rule+
        +modularity-file-name-rule+
        +agent-intent-rule+
        +agent-generic-owner-rule+
        +agent-export-conflict-rule+
        +agent-vague-definition-rule+
        +agent-top-level-executable-rule+
        +agent-poo-direct-writeenv-rule+
        +agent-poo-io-runtime-witness-rule+
        +agent-poo-method-shape-rule+
        +agent-functional-idiom-advice-rule+
        +agent-poo-object-model-rule+
        +agent-macro-runtime-source-witness-rule+
        +agent-protocol-evidence-rule+
        +agent-typed-combinator-style-rule+
        +agent-controlled-branch-shape-rule+
        +agent-comment-quality-rule+
        +agent-predicate-family-combinator-rule+
        +agent-dependency-protocol-adapter-rule+
        +agent-explicit-precise-import-rule+
        +agent-package-build-responsibility-rule+
        +agent-build-runtime-quality-rule+
        +agent-policy-source-scope-rule+
        +agent-alist-access-rule+
        +agent-anonymous-pair-access-rule+
        +agent-package-build-canonical-shape-rule+
        +agent-poo-prototype-fixed-point-rule+
        +agent-poo-construction-performance-rule+
        +agent-poo-clone-override-loop-performance-rule+
        +agent-poo-materialization-loop-performance-rule+
        +agent-poo-composition-loop-performance-rule+
        +agent-poo-validation-loop-performance-rule+
        +agent-poo-lens-loop-performance-rule+
        +agent-poo-object-construction-loop-performance-rule+
        +agent-poo-type-construction-loop-performance-rule+
        +agent-poo-debug-instrumentation-loop-performance-rule+
        +agent-poo-slot-spec-mutation-loop-performance-rule+
        +agent-poo-slot-predicate-loop-performance-rule+
        +agent-poo-documentation-usage-rule+
        +agent-poo-generated-receipt-boundary-rule+
        +agent-list-growth-loop-performance-rule+
        +agent-macro-expansion-io-boundary-rule+
        +agent-list-random-access-loop-performance-rule+
        +agent-string-growth-loop-performance-rule+
        +macro-governance-admission-rule+)
;; PolicyRuleStruct
(defstruct policy-rule (id severity))
;; Integer
(def +modularity-facade-rule+
  (make-policy-rule "GERBIL-SCHEME-MOD-R001" "warning"))
;; Integer
(def +modularity-source-leaf-rule+
  (make-policy-rule "GERBIL-SCHEME-MOD-R002" "warning"))
;; Integer
(def +modularity-owner-collision-rule+
  (make-policy-rule "GERBIL-SCHEME-MOD-R003" "warning"))
;; Integer
(def +modularity-repeated-owner-entry-rule+
  (make-policy-rule "GERBIL-SCHEME-MOD-R004" "warning"))
;; Integer
(def +modularity-bin-entrypoint-rule+
  (make-policy-rule "GERBIL-SCHEME-MOD-R005" "warning"))
;; Integer
(def +modularity-test-directory-rule+
  (make-policy-rule "GERBIL-SCHEME-MOD-R006" "warning"))
;; Integer
(def +modularity-test-leaf-rule+
  (make-policy-rule "GERBIL-SCHEME-MOD-R007" "warning"))
;; Integer
(def +modularity-file-name-rule+
  (make-policy-rule "GERBIL-SCHEME-MOD-R008" "warning"))
;; ConfigConstant
(def +agent-intent-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-POLICY-001" "warning"))
;; ConfigConstant
(def +agent-generic-owner-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-POLICY-002" "warning"))
;; ConfigConstant
(def +agent-export-conflict-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-POLICY-003" "warning"))
;; ConfigConstant
(def +agent-vague-definition-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-POLICY-004" "warning"))
;; ConfigConstant
(def +agent-top-level-executable-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-POLICY-005" "warning"))
;; ConfigConstant
(def +agent-poo-direct-writeenv-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-POLICY-006" "warning"))
;; ConfigConstant
(def +agent-poo-io-runtime-witness-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-POLICY-007" "warning"))
;; ConfigConstant
(def +agent-poo-method-shape-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-POLICY-008" "warning"))
;; String
(def +agent-functional-idiom-advice-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-POLICY-009" "warning"))
;; ConfigConstant
(def +agent-poo-object-model-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-POLICY-010" "warning"))
;; ConfigConstant
(def +agent-macro-runtime-source-witness-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-POLICY-011" "warning"))
;; String
(def +agent-protocol-evidence-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-POLICY-012" "warning"))
;; TypeSpec
(def +agent-typed-combinator-style-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-POLICY-013" "warning"))
;; ConfigConstant
(def +agent-controlled-branch-shape-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-POLICY-014" "warning"))
;; ConfigConstant
(def +agent-comment-quality-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-POLICY-015" "warning"))
;; ConfigConstant
(def +agent-predicate-family-combinator-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-POLICY-016" "warning"))
;; ConfigConstant
(def +agent-dependency-protocol-adapter-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-POLICY-017" "warning"))
;; ConfigConstant
(def +agent-explicit-precise-import-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-POLICY-018" "warning"))
;; ConfigConstant
(def +agent-package-build-responsibility-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-POLICY-019" "warning"))
;; ConfigConstant
(def +agent-build-runtime-quality-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-POLICY-020" "warning"))
;; ConfigConstant
(def +agent-policy-source-scope-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-POLICY-021" "warning"))
;; ConfigConstant
(def +agent-alist-access-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-POLICY-022" "warning"))
;; ConfigConstant
(def +agent-anonymous-pair-access-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-POLICY-023" "warning"))
;; ConfigConstant
(def +agent-package-build-canonical-shape-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-POLICY-025" "warning"))
;; ConfigConstant
(def +agent-poo-prototype-fixed-point-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-POLICY-026" "warning"))
;; ConfigConstant
(def +agent-poo-construction-performance-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-POLICY-027" "warning"))
;; ConfigConstant
(def +agent-poo-clone-override-loop-performance-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-POLICY-028" "warning"))
;; ConfigConstant
(def +agent-poo-materialization-loop-performance-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-POLICY-029" "warning"))
;; ConfigConstant
(def +agent-poo-composition-loop-performance-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-POLICY-030" "warning"))
;; ConfigConstant
(def +agent-poo-validation-loop-performance-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-POLICY-031" "warning"))
;; ConfigConstant
(def +agent-poo-lens-loop-performance-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-POLICY-032" "warning"))
;; ConfigConstant
(def +agent-poo-object-construction-loop-performance-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-POLICY-033" "warning"))
;; ConfigConstant
(def +agent-poo-type-construction-loop-performance-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-POLICY-034" "warning"))
;; ConfigConstant
(def +agent-poo-debug-instrumentation-loop-performance-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-POLICY-035" "warning"))
;; ConfigConstant
(def +agent-poo-slot-spec-mutation-loop-performance-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-POLICY-036" "warning"))
;; ConfigConstant
(def +agent-poo-slot-predicate-loop-performance-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-POLICY-037" "warning"))
;; ConfigConstant
(def +agent-poo-documentation-usage-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-POLICY-038" "warning"))
;; Retired compatibility constant; P043 has no detector or catalog entry.
(def +agent-poo-generated-receipt-boundary-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-POLICY-043" "warning"))
;; ConfigConstant
(def +agent-list-growth-loop-performance-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-POLICY-039" "warning"))
;; ConfigConstant
(def +agent-macro-expansion-io-boundary-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-POLICY-040" "warning"))
;; ConfigConstant
(def +agent-list-random-access-loop-performance-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-POLICY-041" "warning"))
;; ConfigConstant
(def +agent-string-growth-loop-performance-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-POLICY-042" "warning"))
;; Macro governance profile violations stop admission before native build; the
;; stable rule id remains separate from R011 and R040 compatibility findings.
(def +macro-governance-admission-rule+
  (make-policy-rule "GERBIL-SCHEME-MACRO-GOVERNANCE-001" "error"))
