;;; -*- Gerbil -*-
;;; Parser-owned destructuring signals for typed-combinator style policy.

(import :asp-gerbil-scheme/src/parser/facade
        (only-in :std/srfi/13 string-contains)
        (only-in :std/sugar filter ormap))

(export typed-combinator-style-destructuring-quality-facets
        typed-combinator-style-destructuring-signals
        typed-combinator-style-destructuring-targets)

;; (List Callee)
(def +typed-combinator-style-destructuring-callees+
  ["car" "cdr" "caar" "cadr" "cdar" "cddr" "assq" "assoc"
   "hash-get" "list-ref"])

;;; Destructuring boundary:
;;; - gerbil://gerbil/core/match.ss teaches native applicative destructuring,
;;;   syntax-local match extension, and compile-time metadata lookup.
;;; - gerbil-utils/base.ss teaches lambda-match/match boundary style.
;;; - gerbil-poo/mop.ss teaches slot/lens boundaries for object-shaped data.
;;; - Emit only when parser facts prove a structure contract and repeated
;;;   decomposition calls in the same owner.
;; : (-> SourceFile (List QualityFacet) )
(def (typed-combinator-style-destructuring-quality-facets file)
  (append
   (if (pair? (typed-combinator-style-destructuring-facts file))
     ["destructuring-combinator-boundary"
      "gerbil-native-pattern-boundary"
      "match-with-destructuring-boundary"]
     [])
   (if (pair? (typed-combinator-style-pair-tuple-projection-facts file))
     ["pair-tuple-projection-boundary"
      "anonymous-result-protocol"
      "values-tuple-protocol"]
     [])))

;;; Guidance boundary:
;;; - Signals name local repair moves for generated-looking destructuring.
;;; - They do not require importing gerbil-utils or gerbil-poo downstream.
;; : (-> SourceFile (List String) )
(def (typed-combinator-style-destructuring-signals file)
  (append
   (if (pair? (typed-combinator-style-destructuring-facts file))
     ["replace repeated car/cdr/assq scaffolding with a named selector or match boundary"
     "prefer native match/apply destructuring when it removes runtime probing"
      "use with/with* when several local bindings only destructure one shaped value"
      "use alet/alet* for dependent maybe-value chains instead of nested let/and scaffolding"
      "use case for closed datum dispatch before writing equality ladders by hand"
      "use ast-case or syntax-case only when parser facts prove syntax-object or AST shape"
      "use syntax-local metadata lookup when the shape is known at expansion time"
      "keep match-specific macro extension local and early-failing; do not invent broad macro layers"
      "use lambda-match or match when pair shape is the actual interface"
      "use local slot/lens helpers when repeated destructuring is object-slot access"
      "keep temporary let bindings only when they name a real domain boundary"]
     [])
   (if (pair? (typed-combinator-style-pair-tuple-projection-facts file))
     ["replace cons-built Pair tuple returns with values/call-with-values when the pair is not the domain interface"
      "name the tuple projection boundary at the producer and destructure it directly at the consumer"
      "keep Pair returns only when callers need pair/list protocol behavior as the public contract"]
     [])))

;;; Target boundary:
;;; - Report only contract owners whose body has repeated parser-owned
;;;   destructuring calls.
;; : (-> SourceFile (List TargetName) )
(def (typed-combinator-style-destructuring-targets file)
  (append
   (map typed-contract-fact-definition-name
        (typed-combinator-style-destructuring-facts file))
   (map typed-contract-fact-definition-name
        (typed-combinator-style-pair-tuple-projection-facts file))))

;;; Pair tuple projection boundary:
;;; - Real agent code often builds `(cons a b)` only to split it with car/cdr
;;;   in the next helper.
;;; - A Pair result contract plus a same-owner `cons` call is parser-owned
;;;   evidence for replacing the anonymous tuple protocol with `values`.
;; : (-> SourceFile (List TypedContractFact) )
(def (typed-combinator-style-pair-tuple-projection-facts file)
  (filter (lambda (fact)
            (typed-combinator-style-pair-tuple-projection-fact? file fact))
          (source-file-typed-contract-facts file)))

;; : (-> SourceFile TypedContractFact Boolean )
(def (typed-combinator-style-pair-tuple-projection-fact? file fact)
  (and (typed-combinator-style-pair-result-contract? fact)
       (typed-combinator-style-owner-calls?
        file
        (typed-contract-fact-definition-name fact)
        "cons")))

;; : (-> TypedContractFact Boolean )
(def (typed-combinator-style-pair-result-contract? fact)
  (let (output (typed-contract-fact-contract-output fact))
    (and (string? output)
         (or (string-contains output "Pair")
             (string-contains output "pair")
             (string-contains output "Cons")
             (string-contains output "cons")))))

;;; Fact boundary:
;;; - A structure contract alone is not enough; the owner must also carry
;;;   repeated decomposition calls.
;;; - The threshold keeps small selector helpers from warning after repair.
;; : (-> SourceFile (List TypedContractFact) )
(def (typed-combinator-style-destructuring-facts file)
  (filter (lambda (fact)
            (typed-combinator-style-destructuring-fact? file fact))
          (source-file-typed-contract-facts file)))

;;; Contract/call gate keeps detection on parser-owned facts.
;; : (-> SourceFile TypedContractFact Boolean )
(def (typed-combinator-style-destructuring-fact? file fact)
  (and (typed-combinator-style-structure-contract? fact)
       (>= (typed-combinator-style-destructuring-call-count
            file
            (typed-contract-fact-definition-name fact))
           4)))

;;; Structure contracts cover pair/list records, alists, and object-like maps.
;; : (-> TypedContractFact Boolean )
(def (typed-combinator-style-structure-contract? fact)
  (typed-combinator-style-contract-mentions-any?
   fact
   ["Pair" "pair" "Cons" "cons" "Alist" "alist" "Entry" "entry"
    "Record" "record" "Dict" "dict" "Map" "map" "Object" "object"]))

;;; Count only decomposition calls owned by the same definition.
;; : (-> SourceFile DefinitionName Integer )
(def (typed-combinator-style-destructuring-call-count file definition-name)
  (length
   (filter (lambda (call)
             (and (equal? (call-fact-caller call) definition-name)
                  (typed-combinator-style-destructuring-call? call)))
           (source-file-calls file))))

;; : (-> SourceFile DefinitionName Callee Boolean )
(def (typed-combinator-style-owner-calls? file definition-name callee)
  (ormap (lambda (call)
           (and (equal? (call-fact-caller call) definition-name)
                (equal? (call-fact-callee call) callee)))
         (source-file-calls file)))

;;; Callee predicate boundary:
;;; - The destructuring vocabulary is intentionally a small allow-list.
;;; - `ormap` keeps the membership check expression-shaped and prevents this
;;;   policy helper from growing a generated conditional dispatch wall.
;; : (-> CallFact Boolean )
(def (typed-combinator-style-destructuring-call? call)
  (ormap (lambda (callee)
           (equal? (call-fact-callee call) callee))
         +typed-combinator-style-destructuring-callees+))

;;; Contract token boundary:
;;; - Structure evidence is a compact token predicate over parser facts.
;;; - The `terms` list stays data-owned so scenarios can add vocabulary without
;;;   adding another branching helper.
;; : (-> TypedContractFact (List String) Boolean )
(def (typed-combinator-style-contract-mentions-any? fact terms)
  (ormap (lambda (term)
           (typed-combinator-style-contract-mentions? fact term))
         terms))

;;; Token match boundary:
;;; - Use substring matching only on typed-contract tokens already emitted by
;;;   the parser.
;;; - This keeps Scheme-native typed blocks supported without scanning source
;;;   text outside the parser-owned fact payload.
;; : (-> TypedContractFact String Boolean )
(def (typed-combinator-style-contract-mentions? fact term)
  (ormap (lambda (token)
           (string-contains token term))
         (typed-contract-fact-tokens fact)))
