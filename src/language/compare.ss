;;; -*- Gerbil -*-
;;; Stable compare facts for active Gerbil runtime evidence.

(import :asp-gerbil-scheme/src/language/evidence
        (only-in :std/srfi/13 string-contains string-prefix? string-split)
        (only-in :std/sugar cut filter ormap))

(export compare-facts
        matching-compare-facts
        compare-fact-json)
;;; Boundary:
;;; - compare-facts coordinates multiple evidence fields.
;;; - Keep packet shape and invariants stable.
;; (List Fact)
(def (compare-facts)
  (let* ((runtime-fact (car (active-runtime-facts)))
         (details (hash-get runtime-fact 'details))
         (version-string (gerbil-system-version-string)))
    (list
     (hash (id "env-active-documented")
           (summary "Active Gerbil runtime evidence is authoritative over documented or remembered runtime claims.")
           (evidenceGrade "fact")
           (witness "active-runtime-beats-documented-memory")
           (next "search env gxi load-path")
           (terms ["compare" "env" "active" "documented" "runtime" "gxi"
                   "version" version-string])
           (left (hash (kind "active-runtime")
                       (systemVersion version-string)
                       (gxiResolved (hash-get details 'gxiExists))
                       (gscResolved (hash-get details 'gscExists))))
           (right (hash (kind "documented-runtime")
                        (source "documentation-or-model-memory")
                        (status "non-authoritative")))
           (result "active-runtime-authoritative")
           (agentScenario "agent-needs-to-choose-active-gxi-over-documented-or-remembered-version")
           (intent "compare-active-runtime-before-answering-version-sensitive-gerbil-questions")
           (qualitySignals ["active-runtime-fact"
                            "no-memory"
                            "path-free-compare-output"])
           (failureCases
            [(hash (id "documented-version-wins")
                   (risk "agent-follows-documentation-or-model-memory-over-active-gxi")
                   (correction "query-compare-env-active-documented-before-version-sensitive-guidance"))
             (hash (id "compare-leaks-local-path")
                   (risk "agent-copies-active-runtime-absolute-path-into-docs-or-code")
                   (correction "compare-output-must-report-resolution-status-without-local-paths"))]))
     (hash (id "compile-target-runtime-source")
           (summary "Compile-version questions must resolve the active gxi/gsc first, then acquire the matching source checkout before answering syntax or macro usage.")
           (evidenceGrade "fact")
           (witness "active-runtime-selects-versioned-source-before-compile-guidance")
           (next "search runtime-source macro sugar module-sugar")
           (terms ["compare" "compile" "compiler" "gsc" "runtime" "version"
                   "target" "requested" "source" "checkout" "nightly"
                   "0.18" "v0.18" "0.19" "v0.19" version-string])
           (left (hash (kind "active-runtime")
                       (systemVersion version-string)
                       (gxiResolved (hash-get details 'gxiExists))
                       (gscResolved (hash-get details 'gscExists))
                       (sourceAuthority "active-runtime-version")))
           (right (hash (kind "requested-compile-target")
                        (source "agent-request-or-user-claim")
                        (status "non-authoritative-until-runtime-source-acquired")
                        (targetVersions ["v0.18" "v0.19" "nightly"])
                        (compileMode "active-gxi-gsc-first")
                        (stateNamespace "runtime-source/gerbil-scheme")))
           (result "active-runtime-source-checkout-required-before-version-guidance")
           (agentScenario "agent-needs-to-answer-gerbil-compile-or-syntax-question-for-a-requested-version")
           (intent "compare-requested-compile-version-against-active-runtime-and-route-to-versioned-source")
           (qualitySignals ["active-runtime-fact"
                            "compile-version-query"
                            "version-matched-source"
                            "no-memory"
                            "source-checkout-required"])
           (failureCases
            [(hash (id "requested-version-wins-without-runtime")
                   (risk "agent-answers-for-v0-18-v0-19-or-nightly-without-checking-active-gxi")
                   (correction "query-compare-compile-target-runtime-source-before-version-sensitive-guidance"))
             (hash (id "compile-source-mismatch")
                   (risk "agent-uses syntax or macro examples from a different compiler source tree")
                   (correction "route-to-runtime-source-checkout-derived-from-active-runtime-version"))
             (hash (id "nightly-assumption")
                   (risk "agent-treats-nightly-features-as-available-on-the-active-stable-runtime")
                   (correction "verify-active-gxi-gsc-and-matching-source-before-nightly-feature-guidance"))])))))
;;; Boundary:
;;; - matching-compare-facts composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> (List CompareFact) (List CompareFact) )
(def (matching-compare-facts terms)
  (let (facts (compare-facts))
    (if (null? terms)
      facts
      (let (matches (filter (cut compare-fact-matches-terms? <> terms) facts))
        (if (compare-compile-query? terms)
          (focus-compare-fact "compile-target-runtime-source" matches)
          matches)))))
;;; Boundary:
;;; - compare-compile-query? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> (List SearchTerm) Boolean )
(def (compare-compile-query? terms)
  (ormap (lambda (term)
           (or (term-matches-token-list?
                term
                ["compile" "compiler" "gsc" "target" "requested" "runtime"
                 "source" "checkout" "nightly"])
               (string-prefix? "v0." term)
               (string-prefix? "0." term)))
         terms))
;;; Boundary:
;;; - focus-compare-fact composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> CompareAxis (List CompareFact) CompareFact )
(def (focus-compare-fact id facts)
  (let (focused (filter (lambda (fact) (equal? (hash-get fact 'id) id)) facts))
    (if (null? focused) facts focused)))
;;; Boundary:
;;; - compare-fact-matches-terms? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> CompareFact (List SearchTerm) Boolean )
(def (compare-fact-matches-terms? fact terms)
  (ormap (lambda (term)
           (term-matches-token-list? term (hash-get fact 'terms)))
         terms))

;;; Data-flow boundary:
;;; - Direct token containment wins first.
;;; - Hyphenated query terms then require every part to match an evidence token.
;; : (-> SearchTerm (List String) Boolean )
(def (term-matches-token-list? term tokens)
  (or (ormap (cut term-matches-token? term <>) tokens)
      (let (parts (hyphenated-term-parts term))
        (and (pair? (cdr parts))
             (all?
              parts
              (lambda (part)
                (ormap (cut term-matches-token? part <>) tokens)))))))

;; : (-> SearchTerm String Boolean )
(def (term-matches-token? term token)
  (or (string-contains token term)
      (string-contains term token)))

;; hyphenated-term-parts
;;   : (-> SearchTerm (List String))
;;   | doc m%
;;       `hyphenated-term-parts term` splits a search term on hyphen boundaries
;;       and drops empty segments before part-wise token matching.
;;
;;       # Examples
;;
;;       ```scheme
;;       (hyphenated-term-parts "compile-target-runtime")
;;       ;; => ["compile" "target" "runtime"]
;;       ```
;;     %
;;; Intent: this is a pure tokenization transform; use the standard string
;;; splitter plus filter so search matching does not hide a character scanner.
(def (hyphenated-term-parts term)
  (filter (lambda (part) (> (string-length part) 0))
          (string-split term #\-)))

;; : (-> (List X) (-> X Boolean) Boolean )
(def (all? values predicate)
  (or (null? values)
      (and (predicate (car values))
           (all? (cdr values) predicate))))
;; : (-> Fact Json )
(def (compare-fact-json fact)
  (hash (id (hash-get fact 'id))
        (summary (hash-get fact 'summary))
        (evidenceGrade (hash-get fact 'evidenceGrade))
        (witness (hash-get fact 'witness))
        (next (hash-get fact 'next))
        (left (hash-get fact 'left))
        (right (hash-get fact 'right))
        (result (hash-get fact 'result))
        (agentScenario (hash-get fact 'agentScenario))
        (intent (hash-get fact 'intent))
        (qualitySignals (hash-get fact 'qualitySignals))
        (failureCases (hash-get fact 'failureCases))))
