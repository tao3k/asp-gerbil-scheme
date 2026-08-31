;;; -*- Gerbil -*-
;;; Medium-weight TypeSpec proof search surface.

(import :gerbil/gambit
        :asp-gerbil-scheme/src/constants
        :asp-gerbil-scheme/src/commands/search-render
        :asp-gerbil-scheme/src/protocol/json
        :asp-gerbil-scheme/src/support/args
        :asp-gerbil-scheme/src/support/io
        :asp-gerbil-scheme/src/types/facade
        (only-in :std/srfi/13 string-contains string-join)
        (only-in :std/sugar cut filter filter-map hash ormap))

(export emit-type-proof-search)

;; String
(def +semantic-type-proof-schema-id+
  "agent.semantic-protocols.semantic-type-proof")

;; : (-> (List TypeProofExample) (Values EvidenceGrade Quality Missing Witness) )
(def (type-proof-search-summary proofs)
  (if (null? proofs)
    (values "unknown" "insufficient" ["type-proof-example"] "pending")
    (values "fact" "verified" []
            "typespec-proof-tree-and-compiler-evidence-boundary")))
;; : (-> (List TypeProofExample) Unit )
(def (emit-type-proof-examples proofs)
  (if (null? proofs)
    (begin
      (displayln "|missing type-proof-example")
      (displayln "|witness pending"))
    (for-each emit-type-proof-example-line proofs)))

;;; Boundary:
;;; - The command layer projects TypeProof values; it never reimplements the
;;;   subtype relation.
;;; - Compiler evidence is linked as a source-backed boundary, not as a hidden
;;;   theorem-prover dependency.
;; : (-> (List String) Boolean Integer)
(def (emit-type-proof-search args json?)
  (let* ((positionals (positional-args args))
         (query (if (pair? positionals) (string-join positionals " ") "-"))
         (proofs (matching-type-proof-examples positionals))
         (next "search compiler-evidence optimizer subtype assertion"))
    (let-values (((grade quality missing witness)
                  (type-proof-search-summary proofs)))
      (if json?
        (write-json-line
         (type-proof-packet-json query grade quality proofs missing witness next))
        (begin
          (displayln "[gerbil-search-proof] query=" query
                     " evidenceGrade=" grade
                     " authority=medium-weight-type-proof"
                     " quality=" quality)
          (emit-type-proof-system-lines)
          (emit-type-proof-examples proofs)
          (emit-type-proof-compiler-evidence-line)
          (for-each emit-type-proof-failure-case-line (type-proof-failure-cases))
          (for-each emit-type-proof-quality-signal-line (type-proof-quality-signals))
          (displayln "next=" next)))
      0)))

;; : (-> Query EvidenceGrade Quality (List TypeProofExample) Missing Witness Next JsonPacket)
(def (type-proof-packet-json query grade quality proofs missing witness next)
  (hash (schemaId +semantic-type-proof-schema-id+)
        (schemaVersion "1")
        (protocolId "agent.semantic-protocols.semantic-language")
        (protocolVersion "1")
        (languageId +language-id+)
        (providerId +provider-id+)
        (namespace "proof")
        (authority "medium-weight-type-proof")
        (evidenceGrade grade)
        (quality quality)
        (query query)
        (proofSystem (type-proof-system-json))
        (proofs proofs)
        (compilerEvidence (type-proof-compiler-evidence-json))
        (failureCases (type-proof-failure-cases))
        (qualitySignals (type-proof-quality-signals))
        (missing missing)
        (witness witness)
        (next next)))

;; : (-> Json)
(def (type-proof-system-json)
  (hash (id "gerbil-medium-weight-type-proof")
        (level "medium-weight")
        (engine "src/types/subtyping.ss")
        (model "TypeSpec")
        (claim "positive-derivation-witness")
        (relations ["alias-equivalent" "subtype" "compatible"])
        (ruleCatalog (type-proof-rule-catalog))
        (openTypePolicy "unknown-any-variable-compatible-only")
        (sourceBoundary "parser-contract-to-normalized-typespec")
        (compilerEvidenceNamespace "compiler-evidence")
        (notA ["general-constraint-solver"
               "quantifier-reasoning"
               "principal-type-inference"
               "proof-term-calculus"
               "cross-module-theorem-prover"])))

;; : (-> (List String))
(def (type-proof-rule-catalog)
  ["type-equal" "expected-any" "null-list" "refine" "refine-base"
   "union-right" "union-left" "list" "vector" "maybe" "pair"
   "list-pair" "hash" "values" "application" "function"
   "function-variadic" "record" "record-field" "alias-equivalent"
   "compatible-open-actual" "compatible-open-expected" "compatible-subtype"])

;; : (-> Json)
(def (type-proof-compiler-evidence-json)
  (hash (namespace "compiler-evidence")
        (authority "compiler-metadata-source")
        (nextCommand "search compiler-evidence optimizer subtype assertion")
        (selectors ["gerbil-runtime-source://src/gerbil/compiler/optimize-base.ss#!type-subtype?"
                    "gerbil-runtime-source://src/gerbil/compiler/optimize-ann.ss#assert-type"])
        (boundary "Gerbil compiler metadata supports medium-weight evidence only")))

;; : (-> (List FailureCase))
(def (type-proof-failure-cases)
  [(hash (id "full-proof-system-claim")
         (risk "agent-treats-medium-weight-typeproof-as-complete-type-theory")
         (correction "limit-claims-to-positive-derivation-witnesses-and-query-compiler-evidence"))
   (hash (id "proof-without-typespec-validation")
         (risk "agent-uses-comment-contract-text-without-normalized-typespec-validation")
         (correction "parse-and-validate-typespec-before-building-typeproof"))
   (hash (id "compiler-evidence-missing")
         (risk "agent-repairs-type-contracts-without-versioned-gerbil-compiler-boundary")
         (correction "cite-search-compiler-evidence-before-claiming-medium-weight-proof"))])

;; : (-> (List QualitySignal))
(def (type-proof-quality-signals)
  ["schema-backed-proof-packet"
   "recursive-proof-json"
   "proof-cost-depth-node-count"
   "typespec-validation-first"
   "compiler-evidence-linked"
   "no-full-proof-claim"])

;; : (-> Unit)
(def (emit-type-proof-system-lines)
  (displayln "|proofSystem id=gerbil-medium-weight-type-proof"
             " level=medium-weight"
             " engine=src/types/subtyping.ss"
             " model=TypeSpec"
             " claim=positive-derivation-witness"
             " relations=" (join-or-dash ["alias-equivalent" "subtype" "compatible"])))

;; : (-> TypeProofExample Unit)
(def (emit-type-proof-example-line proof)
  (let (profile (hash-get proof 'profile))
    (displayln "|proof id=" (hash-get proof 'id)
               " relation=" (hash-get proof 'relation)
               " rootRule=" (hash-get profile 'rootRule)
               " depth=" (hash-get profile 'depth)
               " nodeCount=" (hash-get profile 'nodeCount)
               " rules=" (join-or-dash (hash-get profile 'rules))
               " conclusion=" (join-or-dash (hash-get profile 'conclusion)))))

;; : (-> Unit)
(def (emit-type-proof-compiler-evidence-line)
  (displayln "|compilerEvidence namespace=compiler-evidence"
             " authority=compiler-metadata-source"
             " nextCommand=search compiler-evidence optimizer subtype assertion"))

;; : (-> FailureCase Unit)
(def (emit-type-proof-failure-case-line failure)
  (displayln "|failureCase id=" (hash-get failure 'id)
             " risk=" (hash-get failure 'risk)
             " correction=" (hash-get failure 'correction)))

;; : (-> QualitySignal Unit)
(def (emit-type-proof-quality-signal-line signal)
  (displayln "|qualitySignal id=" signal))

;;; Query terms are a pure filter over pre-built proof witnesses.  Keeping the
;;; selection as `filter` plus a predicate preserves fixture order and avoids a
;;; second proof construction path in the command renderer.
;; : (-> (List String) (List TypeProofExample))
(def (matching-type-proof-examples terms)
  (filter (cut type-proof-example-matches-terms? <> terms)
          (type-proof-examples)))

;;; Matching is existential across user terms and example tags.  The nested
;;; `ormap` form makes the no-ranking/no-normalization invariant explicit for
;;; agent-facing search evidence.
;; : (-> TypeProofExample (List String) Boolean)
(def (type-proof-example-matches-terms? example terms)
  (or (null? terms)
      (ormap (lambda (term)
               (ormap (cut string-contains <> term)
                      (hash-get example 'terms)))
             terms)))

;;; Proof examples are generated through the TypeSpec proof engine.  They are
;;; fixtures for search evidence, not an alternate implementation of subtyping.
;; : (-> (List TypeProofExample))
(def (type-proof-examples)
  (let* ((number-type (parse-type-contract "Number"))
         (string-type (parse-type-contract "String"))
         (refined-number (parse-type-contract "(Refine Number natural?)"))
         (string-or-number (parse-type-contract "(U String Number)"))
         (number-list (parse-type-contract "(List Number)"))
         (box-alias-env
          (type-alias-env-bind-type
           (make-type-alias-env)
           "Box"
           ["a"]
           (make-type-list (make-type-variable "a"))))
         (box-number (parse-type-contract "(Box Number)"))
         (expected-record (make-type-record
                           (list (cons "value" number-type))
                           ["value"]))
         (actual-record (make-type-record
                         (list (cons "value" refined-number)
                               (cons "tag" string-type))
                         ["value"]))
         (actual-function (make-type-function [number-type] string-type))
         (expected-function (make-type-function [refined-number] string-type)))
    (filter-map
     (lambda (value) value)
     [(type-proof-example
       "refined-number-union-subtype"
       "subtype"
       (type-subtype-proof refined-number string-or-number)
       ["proof" "subtype" "refine" "union" "typespec" "formal"])
      (type-proof-example
       "record-width-subtype"
       "subtype"
       (type-subtype-proof actual-record expected-record)
       ["proof" "subtype" "record" "width" "stable" "typespec"])
      (type-proof-example
       "alias-equivalence"
       "alias-equivalent"
       (type-alias-equivalence-proof box-number number-list box-alias-env)
       ["proof" "alias" "equivalent" "typespec" "validation"])
      (type-proof-example
       "alias-compatible"
       "compatible"
       (type-compatible-proof box-number number-list box-alias-env)
       ["proof" "compatible" "alias" "repair" "gate"])
      (type-proof-example
       "function-contravariant-subtype"
       "subtype"
       (type-subtype-proof actual-function expected-function)
       ["proof" "function" "contravariant" "formal" "typespec"])])))

;; : (-> ProofId Relation (Maybe TypeProof) Terms (Maybe TypeProofExample))
(def (type-proof-example id relation proof terms)
  (and proof
       (hash (id id)
             (relation relation)
             (terms terms)
             (profile (type-proof-profile-json proof))
             (proof (type-proof-json proof)))))
