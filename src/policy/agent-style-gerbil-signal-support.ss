;;; -*- Gerbil -*-
;;; Shared helpers for Gerbil-specific style signal projection.

(import :asp-gerbil-scheme/src/parser/facade
        (only-in :std/srfi/13 string-contains)
        (only-in :std/sugar ormap))

(export typed-combinator-style-facts->quality-facet
        typed-combinator-style-facts->signals
        typed-combinator-style-facts->targets
        typed-contract-fact-mentions-any?)

;;; Facet helper boundary:
;;; - Converts proven parser facts into one public quality facet.
;;; - Empty facts mean no guidance; callers still own fact discovery.
;; : (forall (fact) (-> (List fact) QualityFacet (List QualityFacet)) )
(def (typed-combinator-style-facts->quality-facet facts facet)
  (if (pair? facts) [facet] []))

;;; Signal helper boundary:
;;; - Keeps feature signal lists declarative beside each feature owner.
;;; - The helper only gates on parser facts and never performs detection.
;; : (forall (fact) (-> (List fact) (List String) (List String)) )
(def (typed-combinator-style-facts->signals facts signals)
  (if (pair? facts) signals []))

;;; Target helper boundary:
;;; - Projects parser fact owners into compact policy target names.
;;; - The accessor keeps typed-contract, macro, and POO facts separate.
;; : (forall (fact) (-> (List fact) (-> fact TargetName) (List TargetName)) )
(def (typed-combinator-style-facts->targets facts target-name)
  (map target-name facts))

;;; Matching boundary:
;;; - Match candidate spellings across tokens, output, and inputs.
;;; - This keeps nested Scheme-native contract projections from losing evidence.
;; : (-> TypedContractFact (List String) Boolean )
(def (typed-contract-fact-mentions-any? fact needles)
  (ormap (lambda (needle)
           (typed-contract-fact-mentions? fact needle))
         needles))

;;; Text boundary:
;;; - This is bounded to parser-owned typed-contract fields.
;;; - It must not expand into source-file scanning or dependency detection.
;; : (-> TypedContractFact String Boolean )
(def (typed-contract-fact-mentions? fact needle)
  (or (member needle (typed-contract-fact-tokens fact))
      (and (string? (typed-contract-fact-contract-output fact))
           (string-contains (typed-contract-fact-contract-output fact)
                            needle))
      (ormap (lambda (input)
               (and (string? input)
                    (string-contains input needle)))
             (typed-contract-fact-contract-inputs fact))))
