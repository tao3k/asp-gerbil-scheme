;;; -*- Gerbil -*-
;;; Focused function-quality signals derived from call and higher-order facts.

(import :asp-gerbil-scheme/src/parser/model
        (only-in :std/sugar cut filter foldl ormap))

(export function-quality-dynamic-scope-cleanup-facets
        typed-contract-profile-facets
        function-quality-higher-order-profile-facets)

(def +function-quality-dynamic-state-callees+
  '("current-directory" "current-input-port" "current-output-port"
    "current-error-port"))

(def +function-quality-dynamic-cleanup-callees+
  '("dynamic-wind" "with-unwind-protect" "parameterize"
    "call-with-parameters"))

;; : (-> CallFacts (List QualityFacet) )
(def (function-quality-dynamic-scope-cleanup-facets calls)
  (if (and (>= (function-quality-call-count-any
                calls +function-quality-dynamic-state-callees+) 2)
           (not (function-quality-call-any?
                 calls +function-quality-dynamic-cleanup-callees+)))
    ["dynamic-scope-cleanup-boundary"
     "manual-dynamic-scope-restore"
     "anti-ai-dynamic-state-restore"]
    []))

(def (function-quality-call-count-any calls callees)
  (foldl (lambda (call count)
           (if (member (call-fact-callee call) callees) (+ count 1) count))
         0 calls))

(def (function-quality-call-any? calls callees)
  (ormap (lambda (call) (member (call-fact-callee call) callees)) calls))

(def (typed-contract-profile-facets fact)
  (typed-contract-fact-quality-facets fact))

;; : (-> (List HigherOrderFact) (List QualityFacet) )
(def (function-quality-higher-order-profile-facets higher-order-forms)
  (let* ((roles (map higher-order-fact-role higher-order-forms))
         (anonymous-formals
          (function-quality-anonymous-formal-groups higher-order-forms))
         (anonymous-count (length anonymous-formals))
         (multi-arity? (member "multi-arity-function" roles))
         (specializer?
          (function-quality-role-list-any?
           roles ["partial-application" "function-curry"]))
         (pipeline?
          (function-quality-role-list-any?
           roles ["function-composition" "pipeline-composition"]))
         (sequence?
          (function-quality-role-list-any?
           roles ["sequence-map" "sequence-filter" "sequence-filter-map"
                  "sequence-append-map" "sequence-predicate" "sequence-search"
                  "sequence-fold"]))
         (driver?
          (function-quality-role-list-any?
           roles ["generator-transform" "generator-control-inversion"
                  "stateful-protocol-wrapper" "loop-fold" "list-builder"]))
         (constructor?
          (and multi-arity? (or (> anonymous-count 0) specializer? pipeline?)))
         (wrapper-drift?
          (and (>= anonymous-count 3)
               (function-quality-repeated-formals? anonymous-formals 3)
               (not multi-arity?) (not specializer?) (not pipeline?)
               (not sequence?) (not driver?))))
    (filter identity
            [(and (or specializer? pipeline?)
                  "base-style-combinator-composition")
             (and constructor? "higher-order-constructor-abstraction")
             (and (and constructor? (> anonymous-count 0))
                  "arity-specialized-function-factory")
             (and wrapper-drift? "wrapper-lambda-drift")
             (and wrapper-drift? "function-specialization-opportunity")])))

(def (function-quality-anonymous-formal-groups higher-order-forms)
  (filter function-quality-informative-formals?
          (map higher-order-fact-formals
               (filter (lambda (fact)
                         (equal? (higher-order-fact-role fact)
                                 "anonymous-function"))
                       higher-order-forms))))

(def (function-quality-role-list-any? roles expected-roles)
  (ormap (lambda (role) (member role roles)) expected-roles))

(def (function-quality-repeated-formals? formal-groups minimum-count)
  (ormap (lambda (formals)
           (>= (function-quality-formals-count formal-groups formals)
               minimum-count))
         formal-groups))

(def (function-quality-formals-count formal-groups formals)
  (length (filter (cut equal? <> formals) formal-groups)))

(def (function-quality-informative-formals? formals)
  (and (pair? formals) (not (member "_" formals))))
