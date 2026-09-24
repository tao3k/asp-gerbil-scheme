;;; -*- Gerbil -*-
;;; Gerbil POO typeclass algebra pattern specs.

(import :asp-gerbil-scheme/src/extensions/poo-pattern-support)

(export +poo-typeclass-algebra-pattern-spec+)

;;; Boundary:
;;; - Typeclass algebra guidance comes from gerbil-poo/fun.ss, not generic FP
;;;   names.
;;; - Keep Category/Functor/Wrapper advice tied to concrete POO define-type
;;;   slots.
;; PatternSpec
(def +poo-typeclass-algebra-pattern-spec+
  (make-poo-pattern-spec
   id: "poo-typeclass-algebra"
   defaultFocus: "typeclass algebra functor wrapper category"
   sourceOwners: ["fun.ss"]
   agentScenario: "agent-writes-poo-typeclasses-without-fun-ss-algebra"
   agentSteering: "query fun.ss algebra selectors before writing Gerbil POO typeclass code; avoid generic FP vocabulary unless Category/Functor/Wrapper slots are present"
   intent: "query-gerbil-poo-fun-algebra-before-writing-category-functor-wrapper-types"
   selectors:
   [(poo-selector "category-algebra"
                  "Category."
                  "gerbil-poo://fun.ss#Category.")
    (poo-selector "functor-algebra"
                  "Functor."
                  "gerbil-poo://fun.ss#Functor.")
    (poo-selector "parametric-functor-algebra"
                  "ParametricFunctor."
                  "gerbil-poo://fun.ss#ParametricFunctor.")
    (poo-selector "identity-functor-witness"
                  "Identity"
                  "gerbil-poo://fun.ss#Identity")
    (poo-selector "wrapper-algebra"
                  "Wrapper."
                  "gerbil-poo://fun.ss#Wrapper.")
    (poo-selector "wrapped-type-algebra"
                  "Wrap."
                  "gerbil-poo://fun.ss#Wrap.")
    (poo-selector "dependent-functor-algebra"
                  "Functor^."
                  "gerbil-poo://fun.ss#Functor^.")]
   minimalForms:
   [(poo-form-mapping "category-algebra"
                      "Category."
                      "define-type"
                      ["@ Type." "Arrow" "domain" "codomain"
                       "compose" "identity"]
                      ["compose-associativity" "identity-laws"]
                      "gerbil-poo://fun.ss#Category.")
    (poo-form-mapping "functor-algebra"
                      "Functor."
                      "define-type"
                      ["@ Type." "Domain" "Codomain" ".ap" ".map"]
                      ["map-over-arrows"]
                      "gerbil-poo://fun.ss#Functor.")
    (poo-form-mapping "parametric-functor-algebra"
                      "ParametricFunctor."
                      "define-type"
                      ["@ [Functor.]" ".tap" ".ap" ".map"]
                      ["type-parameter-independent-code"]
                      "gerbil-poo://fun.ss#ParametricFunctor.")
    (poo-form-mapping "wrapper-algebra"
                      "Wrapper."
                      "define-type"
                      [".ap" ".unap" ".bind" ".map"]
                      ["wrap-unwrapped-value-before-return"]
                      "gerbil-poo://fun.ss#Wrapper.")]
   failureCases:
   [(poo-failure-case "category-without-laws"
                      "typeclass-algebra-contract"
                      "category-like-type-without-compose-identity-law-boundary"
                      "follow-Category.-compose-identity-shape-before-adding-methods"
                      ["gerbil-poo://fun.ss#Category."])
    (poo-failure-case "functor-without-map-ap"
                      "typeclass-algebra-contract"
                      "functor-like-type-that-skips-.ap-or-.map-slots"
                      "follow-Functor.-and-ParametricFunctor.-slot-shapes"
                      ["gerbil-poo://fun.ss#Functor."
                       "gerbil-poo://fun.ss#ParametricFunctor."])
    (poo-failure-case "wrapper-without-unap-bind"
                      "wrapper-algebra-contract"
                      "wrapper-type-that-only-wraps-values-without-unap-bind-map"
                      "follow-Wrapper.-and-Wrap.-algebra-before-specializing"
                      ["gerbil-poo://fun.ss#Wrapper."
                       "gerbil-poo://fun.ss#Wrap."])]
   qualitySignals: ["typeclass-algebra-source" "category-compose-identity"
                    "functor-map-ap" "parametric-functor-tap"
                    "wrapper-bind-map" "identity-functor-witness"
                    "dependent-functor-witness"]
   witness: "gerbil-poo-fun-typeclass-algebra-witness"
   missing: []
   next: "search pattern poo typeclass algebra"))
