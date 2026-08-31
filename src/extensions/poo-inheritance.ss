;;; -*- Gerbil -*-
;;; Inherited pattern facts activated through gerbil-poo dependency closure.
;;; Boundary:
;;; - Owns provider-curated gerbil-poo -> gerbil-utils closure facts only.
;;; - Does not inspect ambient load paths or mutate package declarations.

(import :asp-gerbil-scheme/src/package-manager/facade
        (only-in :std/srfi/13 string-join)
        (only-in :std/sugar hash ormap))

(export poo-inherited-utils-capability-names
        poo-inherited-utils-pattern-query?
        poo-inherited-utils-pattern-evidence)
;; ConfigConstant
(def +gerbil-utils-dependency+
  "git.cons.io/mighty-gerbils/gerbil-utils")
;; ConfigConstant
(def +gerbil-utils-package+
  "gerbil-utils")
;; (List String)
(def +poo-inherited-utils-pattern-terms+
  '("gerbil-utils"
    "higher-order-control"
    "typed-combinator-style"
    "combinator"
    "combinators"
    "curry"
    "rcurry"
    "fold<-reduce-map"
    "fold"
    "compose"
    "rcompose"
    "pipeline"
    "inherited"))
;; (List CapabilityName)
(def (poo-inherited-utils-capability-names)
  ["inherited-gerbil-utils"
   "higher-order-control"
   "typed-combinator-style"
   "pattern-inheritance"])
;;; Query boundary: these terms activate inherited utility guidance, not generic
;;; text search over every gerbil-utils symbol.
;; : (-> (List PatternTerm) Boolean )
(def (poo-inherited-utils-pattern-query? terms)
  (and (pair? terms)
       (ormap (lambda (term)
                (member term +poo-inherited-utils-pattern-terms+))
              terms)))
;;; Boundary:
;;; - Emit inherited facts only after gerbil-poo has already been activated.
;;; - Keep package closure evidence separate from ambient load-path visibility.
;; : (-> DependencyName (List PatternTerm) Pattern )
(def (poo-inherited-utils-pattern-evidence activation-dependency terms)
  (hash (id "gerbil-utils-higher-order-control")
        (extension "poo")
        (focus (poo-inherited-utils-pattern-focus terms))
        (origin "inherited")
        (via (poo-inherited-utils-dependency-chain activation-dependency))
        (importWitness (poo-inherited-utils-import-witness activation-dependency))
        (sourceRef (poo-inherited-utils-source-ref))
        (sourceOwners ["base.ss" "generator.ss" "t/base-test.ss"])
        (selectors (poo-inherited-utils-selectors))
        (agentScenario "agent-inherits-gerbil-utils-patterns-through-gerbil-poo")
        (intent "use-provider-proven-gerbil-utils-combinators-without-duplicating-direct-dependencies")
        (minimalForms (poo-inherited-utils-minimal-forms))
        (failureCases (poo-inherited-utils-failure-cases))
        (qualitySignals (poo-inherited-utils-quality-signals))
        (witness "inherited-gerbil-utils-package-closure-and-style-audit")
        (missing [])
        (next "guide --code --topic typed-combinator-style --intent style")))
;; : (-> (List PatternTerm) PooPatternFocus )
(def (poo-inherited-utils-pattern-focus terms)
  (if (and (pair? terms) (pair? (cdr terms)))
    (string-join terms " ")
    "higher-order-control typed-combinator-style"))
;; : (-> DependencyName (List DependencyName) )
(def (poo-inherited-utils-dependency-chain activation-dependency)
  [activation-dependency +gerbil-utils-dependency+])
;; : (-> DependencyName ImportWitness )
(def (poo-inherited-utils-import-witness activation-dependency)
  (hash (status "verified")
        (module ":clan/base")
        (minimalImport "(import (only-in :clan/base curry rcurry fold<-reduce-map compose rcompose !>))")
        (evidence "gerbil-poo-provider-closure-load-path-import-witness")
        (activation "gerbil.pkg")
        (dependencyChain (poo-inherited-utils-dependency-chain activation-dependency))))
;; SourceRef
(def (poo-inherited-utils-source-ref)
  (hash (kind "package-manager-source")
        (manager "gxpkg")
        (package +gerbil-utils-package+)
        (dependency +gerbil-utils-dependency+)
        (repository +gerbil-utils-dependency+)
        (localSource
         (gerbil-local-source-candidate +gerbil-utils-dependency+))
        (repositorySource
         (git-repository-candidate +gerbil-utils-dependency+))
        (indexHint (package-source-index-hint))
        (pathPolicy "runtime-resolved")
        (selectorScheme "gerbil-utils-logical-symbol")))
;;; Boundary:
;;; - Selectors point at source-backed gerbil-utils combinators and audit notes.
;;; - Keep each role narrow enough for guide --code follow-up to stay token-light.
;; (List Selector)
(def (poo-inherited-utils-selectors)
  [(hash (role "left-to-right-composition")
         (symbol "rcompose")
         (selector "gerbil-utils://base.ss#rcompose"))
   (hash (role "right-to-left-composition")
         (symbol "compose")
         (selector "gerbil-utils://base.ss#compose"))
   (hash (role "pipeline-composition")
         (symbol "!>")
         (selector "gerbil-utils://base.ss#!>"))
   (hash (role "left-curry")
         (symbol "curry")
         (selector "gerbil-utils://base.ss#curry"))
   (hash (role "right-curry")
         (symbol "rcurry")
         (selector "gerbil-utils://base.ss#rcurry"))
   (hash (role "fold-from-reduce-map")
         (symbol "fold<-reduce-map")
         (selector "gerbil-utils://base.ss#fold<-reduce-map"))
   (hash (role "style-audit")
         (symbol "scheme-style")
         (selector "gerbil-utils-audit://docs/10-19-research/11.02-gerbil-utils-engineering-audit.org#scheme-style"))])
;; (List Form)
(def (poo-inherited-utils-minimal-forms)
  [(hash (role "left-curry")
         (symbol "curry")
         (template (hash (head "curry")
                         (operands ["<f>" "<x>"])
                         (keywords ["type-comment:(Z <- YY) <- (Z <- XX YY) XX"])))
         (selector "gerbil-utils://base.ss#curry"))
   (hash (role "right-curry")
         (symbol "rcurry")
         (template (hash (head "rcurry")
                         (operands ["<f>" "<x>"])
                         (keywords ["type-comment:(Z <- YY) <- (Z <- YY XX) XX"])))
         (selector "gerbil-utils://base.ss#rcurry"))
   (hash (role "fold-from-reduce-map")
         (symbol "fold<-reduce-map")
         (template (hash (head "fold<-reduce-map")
                         (operands ["<reduce>" "<map>"])
                         (keywords ["compose-chain" "monoid-reduce-map"])))
         (selector "gerbil-utils://base.ss#fold<-reduce-map"))])
;; (List FailureCase)
(def (poo-inherited-utils-failure-cases)
  [(hash (id "ambient-load-path-import")
         (risk "agent-imports-gerbil-utils-because-machine-load-path-happens-to-contain-it")
         (correction "require origin=inherited with a provider-owned dependency chain before using inherited APIs")
         (selectors ["gerbil-utils://base.ss#curry" "gerbil-utils://base.ss#fold<-reduce-map"]))
   (hash (id "manual-loop-drift")
         (risk "agent-writes-open-coded-recursion-where-gerbil-utils-combinators-provide-a-smaller-verifiable-expression")
         (correction "prefer curry/rcurry/compose/fold<-reduce-map when parser facts show pure expression-level composition")
         (selectors ["gerbil-utils://base.ss#compose" "gerbil-utils://base.ss#fold<-reduce-map"]))
   (hash (id "comment-free-combinator")
         (risk "agent-copies-the-function-shape-without-the-adjacent-algebraic-contract-comment")
         (correction "preserve Haskell-like transform comments and optimization-boundary comments for specialized branches")
         (selectors ["gerbil-utils://base.ss#curry" "gerbil-utils://base.ss#rcurry"]))])
;; (List QualitySignal)
(def (poo-inherited-utils-quality-signals)
  ["package-closure-inheritance"
   "active-load-path-import-witness"
   "typed-combinator-style"
   "higher-order-control"
   "source-backed-algebraic-contract-comments"])
