;;; -*- Gerbil -*-
;;; Parser-owned quality facet aggregation for typed-combinator style policy.

(import :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/policy/agent-style-gerbil-signals
        :asp-gerbil-scheme/src/policy/agent-style-destructuring-signals
        :asp-gerbil-scheme/src/policy/agent-style-performance-signals
        (only-in :std/misc/list unique)
        (only-in :std/srfi/13 string-prefix?)
        (only-in :std/sugar cut filter ormap))

(export typed-combinator-style-quality-facets
        typed-combinator-style-repair-evidence
        typed-combinator-style-quality-repair-triggered?
        quality-facet-present?
        quality-facet-any?)

;;; Quality facets summarize parser-owned style evidence for a source owner.
;;; Keep advisory signals available even when they do not trigger a finding.
;; : (-> SourceFile (List QualityFacet) )
(def (typed-combinator-style-quality-facets file)
  (unique
   (append
    (apply append
           (map typed-contract-fact-quality-facets
                (source-file-typed-contract-facts file)))
    (apply append
           (map higher-order-quality-facets
                (source-file-higher-order-forms file)))
    (apply append
           (map boolean-condition-fact-quality-facets
                (source-file-boolean-condition-facts file)))
    (apply append
           (map typed-combinator-style-profile-quality-facets
                (source-file-function-quality-profiles file)))
    (typed-combinator-style-generator-quality-facets file)
    (typed-combinator-style-anti-ai-scaffold-quality-facets file)
    (typed-combinator-style-gerbil-upstream-idiom-quality-facets file)
    (typed-combinator-style-list-combinator-quality-facets file)
    (typed-combinator-style-std-sugar-flow-quality-facets file)
    (typed-combinator-style-loop-driver-quality-facets file)
    (typed-combinator-style-parser-combinator-boundary-quality-facets file)
    (typed-combinator-style-destructuring-quality-facets file)
    (typed-combinator-style-serialization-boundary-quality-facets file)
    (typed-combinator-style-slot-lens-boundary-quality-facets file)
    (typed-combinator-style-concurrency-control-quality-facets file)
    (typed-combinator-style-dynamic-scope-cleanup-quality-facets file)
    (typed-combinator-style-ssxi-optimizer-metadata-boundary-quality-facets
     file)
    (typed-combinator-style-expander-root-boundary-quality-facets file)
    (typed-combinator-style-actor-runtime-boundary-quality-facets file)
    (typed-combinator-style-mop-c3-linearization-boundary-quality-facets file)
    (typed-combinator-style-exception-continuation-boundary-quality-facets file)
    (typed-combinator-style-macro-family-quality-facets file)
    (typed-combinator-style-macro-metaprogramming-decision-quality-facets
     file)
    (typed-combinator-style-syntax-parameter-context-quality-facets file)
    (typed-combinator-style-syntax-local-registry-quality-facets file)
    (typed-combinator-style-phase-aware-macro-boundary-quality-facets file)
    (typed-combinator-style-controlled-macro-quality-facets file)
    (typed-combinator-style-match-extension-boundary-quality-facets file)
    (typed-combinator-style-mop-class-macro-boundary-quality-facets file)
    (typed-combinator-style-upstream-performance-quality-facets file)
    (typed-combinator-style-result-index-scaffold-quality-facets file)
    (typed-combinator-style-typeclass-quality-facets file))))

;;; R015 consumes only the profile facets that steer gerbil-utils/base.ss style
;;; abstraction.  Broader profile facts stay available to search/report without
;;; turning every typed-block shape hint into an actionable warning.
;; : (-> FunctionQualityProfile (List QualityFacet) )
(def (typed-combinator-style-profile-quality-facets profile)
  (filter (lambda (facet)
            (member facet
                    ["base-style-combinator-composition"
                     "higher-order-constructor-abstraction"
                     "arity-specialized-function-factory"
                     "wrapper-lambda-drift"
                     "function-specialization-opportunity"
                     "eta-wrapper-drift"
                     "lambda-match-destructuring"
                     "lambda-match-rewrite-opportunity"
                     "dynamic-scope-cleanup-boundary"
                     "manual-dynamic-scope-restore"
                     "anti-ai-dynamic-state-restore"
                     "method-table-combinator-body"
                     "method-table-lambda-drift"
                     "method-table-low-level-body"]))
          (function-quality-profile-quality-facets profile)))

;;; Repair evidence carries concrete parser witnesses into guide output.
;;; Agents may choose the rewrite shape, but the witness set stays bounded.
;; : (-> SourceFile (List RepairEvidence) )
(def (typed-combinator-style-repair-evidence file)
  (map typed-contract-fact-repair-evidence
       (source-file-typed-contract-facts file)))

;;; Quality facets are parser-owned repair triggers, not passive advice.
;;; The policy turns manual-loop drift into warnings so self-apply can repair.
;; : (-> SourceFile (List QualityFacet) Boolean )
(def (typed-combinator-style-quality-repair-triggered? file quality-facets)
  (or (quality-facet-any? quality-facets
                          ["scheme-native-typed-block-migration"])
      (and (not (typed-combinator-style-positive-quality-covered?
                 quality-facets))
           (quality-facet-any? quality-facets
                               ["manual-loop-drift"
                                "method-table-lambda-drift"
                                "anti-ai-scaffold-boundary"
                                "gerbil-upstream-idiom-boundary"
                                "list-combinator-boundary"
                                "std-sugar-flow-boundary"
                                "parser-combinator-boundary"
                                "destructuring-combinator-boundary"
                                "gerbil-native-pattern-boundary"
                                "match-with-destructuring-boundary"
                                "pair-tuple-projection-boundary"
                                "values-tuple-protocol"
                                "result-index-scaffold"
                                "slot-lens-boundary"
                                "concurrency-control-boundary"
                                "dynamic-scope-cleanup-boundary"
                                "ssxi-optimizer-metadata-boundary"
                                "actor-runtime-boundary"
                                "exception-continuation-boundary"
                                "macro-metaprogramming-decision-boundary"
                                "syntax-parameterized-context-boundary"
                                "syntax-local-registry-boundary"
                                "macro-family-boundary"
                                "phase-aware-macro-boundary"
                                "macro-phase-optimizer-visible-fast-path"
                                "gambit-numeric-primitive-boundary"
                                "gerbil-inline-rule-call-shape"]))
      (and (typed-combinator-style-runtime-wrapper-source-file? file)
           (not (typed-combinator-style-positive-quality-covered?
                 quality-facets))
           (quality-facet-any? quality-facets
                               ["wrapper-lambda-drift"
                                "function-specialization-opportunity"
                                "boolean-normalization-drift"
                                "generated-scaffold-shape"]))))

;;; Positive coverage gate: broad parser facets become warning triggers only
;;; when the file lacks concrete combinator or expression-level evidence.
;; : (-> (List QualityFacet) Boolean )
(def (typed-combinator-style-positive-quality-covered? facets)
  (or (and (quality-facet-present? facets "expression-level-composition")
           (quality-facet-any? facets
                               ["higher-order-used"
                                "combinator-backed"
                                "base-style-combinator-composition"]))
      (and (quality-facet-present? facets "macro-family-boundary")
           (quality-facet-present? facets "typed-doc-block"))
      (quality-facet-any? facets
                          ["native-performance-evidence"
                           "optimizer-visible-hot-loop"
                           "optimizer-visible-call-shape"])))

;;; Facet membership is normalized once so policy triggers read as predicates
;;; instead of carrying generated double-negation scaffolding at call sites.
;; : (-> (List QualityFacet) QualityFacet Boolean )
(def (quality-facet-present? facets facet)
  (if (member facet facets) #t #f))

;;; Candidate checks keep trigger lists data-shaped while returning a strict
;;; boolean for finding assembly and detail packets.
;; : (-> (List QualityFacet) (List QualityFacet) Boolean )
(def (quality-facet-any? facets candidates)
  (ormap (cut quality-facet-present? facets <>) candidates))

;;; Runtime wrapper scope:
;;; - Tests and fixtures can encode negative examples without this extra gate.
;;; - Runtime files need stronger coverage before broad quality facets warn.
;; : (-> SourceFile Boolean )
(def (typed-combinator-style-runtime-wrapper-source-file? file)
  (let (path (source-file-path file))
    (and path
         (not (string-prefix? "t/" path)))))

;;; Native result protocol quality:
;;; - The parser already owns callee and argument facts for `vector-ref`.
;;; - A result-ish temporary indexed by small numeric slots is an anonymous
;;;   tuple protocol; prefer values binding, a named record, or a domain object.
;; : (-> SourceFile (List QualityFacet) )
(def (typed-combinator-style-result-index-scaffold-quality-facets file)
  (if (pair? (typed-combinator-style-result-index-scaffold-calls file))
    ["result-index-scaffold" "anonymous-result-protocol"]
    []))

;; : (-> SourceFile (List CallFact) )
(def (typed-combinator-style-result-index-scaffold-calls file)
  (filter typed-combinator-style-result-index-scaffold-call?
          (source-file-calls file)))

;; : (-> CallFact Boolean )
(def (typed-combinator-style-result-index-scaffold-call? call)
  (and (equal? (call-fact-callee call) "vector-ref")
       (typed-combinator-style-result-index-arguments?
        (call-fact-arguments call))))

;; : (-> (List Argument) Boolean )
(def (typed-combinator-style-result-index-arguments? arguments)
  (and (pair? arguments)
       (pair? (cdr arguments))
       (typed-combinator-style-result-name? (car arguments))
       (member (cadr arguments) ["0" "1" "2" "3"])))

;; : (-> Argument Boolean )
(def (typed-combinator-style-result-name? value)
  (and value
       (or (equal? value "result")
           (typed-combinator-style-string-suffix? "-result" value))))

;; : (-> String String Boolean )
(def (typed-combinator-style-string-suffix? suffix value)
  (let ((suffix-length (string-length suffix))
        (value-length (string-length value)))
    (and (>= value-length suffix-length)
         (string=? (substring value
                              (- value-length suffix-length)
                              value-length)
                   suffix))))
