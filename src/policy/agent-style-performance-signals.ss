;;; -*- Gerbil -*-
;;; Upstream performance quality signals for R013 typed-combinator guidance.

(import :asp-gerbil-scheme/src/parser/facade
        (only-in :std/misc/list unique)
        (only-in :std/sugar filter))

(export typed-combinator-style-upstream-performance-quality-facets)

;; (List String)
(def +typed-combinator-style-generic-numeric-callees+
  '("+" "-" "*" "/" "<" ">" "<=" ">=" "="))

;; (List String)
(def +typed-combinator-style-gambit-numeric-callees+
  '("fx+" "fx-" "fx*" "fx/" "fx<" "fx>" "fx<=" "fx>=" "fx="
    "fl+" "fl-" "fl*" "fl/" "fl<" "fl>" "fl<=" "fl>=" "fl="
    "##fx+" "##fx-" "##fx*" "##fx<" "##fx>" "##fx<=" "##fx>="
    "##fx="
    "##fl+" "##fl-" "##fl*" "##fl<" "##fl>" "##fl<=" "##fl>="
    "##fl="))

;;; Upstream performance facets:
;;; - Keep this derived from parser-owned callFacts and loopDriverFacts.
;;; - Generic numeric hot loops and repeated dynamic apply hide the call shape
;;;   Gerbil/Gambit optimizers need for fx/fl and inline-rule specialization.
;; : (-> SourceFile (List QualityFacet) )
(def (typed-combinator-style-upstream-performance-quality-facets file)
  (unique
   (append
    (typed-combinator-style-performance-facets
     (typed-combinator-style-generic-numeric-hot-loop? file)
     ["gambit-numeric-primitive-boundary"
      "generic-numeric-hot-loop"
      "numeric-domain-contract-missing"])
    (typed-combinator-style-performance-facets
     (typed-combinator-style-gambit-numeric-hot-loop? file)
     ["gambit-numeric-primitive-boundary"
      "numeric-domain-contract"
      "optimizer-visible-hot-loop"
      "native-performance-evidence"])
    (typed-combinator-style-performance-facets
     (typed-combinator-style-dynamic-apply-hot-loop? file)
     ["gerbil-inline-rule-call-shape"
      "dynamic-apply-hot-loop"
      "compiler-inline-rule-obscured"])
    (typed-combinator-style-performance-facets
     (typed-combinator-style-macro-generated-dynamic-apply-hot-loop? file)
     ["macro-phase-optimizer-visible-fast-path"
      "phase-macro-generated-wrapper"
      "optimizer-visible-call-shape"])
    (typed-combinator-style-performance-facets
     (typed-combinator-style-macro-direct-hot-loop? file)
     ["macro-phase-optimizer-visible-fast-path"
      "optimizer-visible-call-shape"
      "native-performance-evidence"]))))

(def (typed-combinator-style-performance-facets enabled? facets)
  (if enabled? facets []))

;; : (-> SourceFile Boolean )
(def (typed-combinator-style-macro-generated-dynamic-apply-hot-loop? file)
  (let (callers (typed-combinator-style-loop-driver-callers file))
    (and (pair? (source-file-macros file))
         (pair? callers)
         (> (typed-combinator-style-call-count file callers '("apply")) 0))))

(def (typed-combinator-style-macro-direct-hot-loop? file)
  (and (pair? (source-file-macros file))
       (pair? (source-file-loop-driver-facts file))
       (not (typed-combinator-style-dynamic-apply-hot-loop? file))))

;; : (-> SourceFile Boolean )
(def (typed-combinator-style-generic-numeric-hot-loop? file)
  (let (callers (typed-combinator-style-loop-driver-callers file))
    (and (pair? callers)
         (>= (typed-combinator-style-call-count
              file callers +typed-combinator-style-generic-numeric-callees+)
             2)
         (= (typed-combinator-style-call-count
             file callers +typed-combinator-style-gambit-numeric-callees+)
            0))))

(def (typed-combinator-style-gambit-numeric-hot-loop? file)
  (let (callers (typed-combinator-style-loop-driver-callers file))
    (and (pair? callers)
         (> (typed-combinator-style-call-count
             file callers +typed-combinator-style-gambit-numeric-callees+)
            0))))

;; : (-> SourceFile Boolean )
(def (typed-combinator-style-dynamic-apply-hot-loop? file)
  (let (callers (typed-combinator-style-loop-driver-callers file))
    (and (pair? callers)
         (>= (typed-combinator-style-call-count file callers '("apply")) 2))))

;;; Numeric call evidence belongs to the same parser-classified loop driver.
;;; This prevents unrelated helpers in one source file from manufacturing a
;;; false hot-loop specialization recommendation.
;; : (-> SourceFile (List DefinitionName))
(def (typed-combinator-style-loop-driver-callers file)
  (filter (lambda (caller) (and caller #t))
          (map loop-driver-fact-caller
               (source-file-loop-driver-facts file))))

;; : (-> SourceFile (List DefinitionName) (List String) Nat )
(def (typed-combinator-style-call-count file callers callees)
  (length
   (filter (lambda (call)
             (and (member (call-fact-caller call) callers)
                  (member (call-fact-callee call) callees)))
           (source-file-calls file))))
