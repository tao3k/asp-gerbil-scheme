;;; -*- Gerbil -*-
;;; Single-pass macro admission over parser-owned project facts.

(import :gerbil/gambit
        :asp-gerbil-scheme/src/macro-governance/model
        :asp-gerbil-scheme/src/parser/facade
        (only-in :asp-gerbil-scheme/src/policy/agent-macro-io
                 macro-expansion-io-boundary-findings)
        (only-in :asp-gerbil-scheme/src/policy/agent-macro-protocol
                 macro-runtime-source-witness-findings)
        (only-in :asp-gerbil-scheme/src/policy/model
                 +agent-macro-expansion-io-boundary-rule+
                 +agent-macro-runtime-source-witness-rule+
                 +macro-governance-admission-rule+
                 policy-rule-id
                 policy-rule-severity)
        (only-in :std/misc/list unique)
        (only-in :std/srfi/1 append-map)
        (only-in :std/sugar filter-map hash)
        :asp-gerbil-scheme/src/types/findings)

(export macro-governance-admit
        macro-governance-findings
        macro-governance-profile-findings
        macro-governance-contracts
        macro-governance-compile-rule-plan)

(def +macro-governance-admission-schema+
  "agent.semantic-protocols.gerbil-scheme-macro-governance-admission")

;; The POO extension surface is compiled once into symbols.  The hot fact walk
;; does not perform object dispatch for every syntax node.
(def (macro-governance-compile-rule-plan profile)
  (map macro-governance-rule-id
       (macro-governance-profile-rules profile)))

;; : (-> ProjectIndex Boolean)
(def (macro-governance-configured? index)
  (let (package (project-index-package index))
    (and package
         (project-package-macro-governance-policy package))))

;; : (-> ProjectIndex (List MacroFact))
(def (macro-governance-macros index)
  (apply append
         (map source-file-macros (project-index-files index))))

;; Contracts project existing package declarations and parser facts; metadata
;; never replaces executable witness admission.
(def (macro-governance-contracts index)
  (let (witnesses (macro-governance-witnesses index))
    (map (lambda (macro)
           (macro-governance-contract-for macro witnesses))
         (macro-governance-macros index))))

;; Package metadata projects witness ownership only; the parser-owned macro
;; fact remains the executable authority used by admission.
(def (macro-governance-witnesses index)
  (let* ((package (project-index-package index))
         (policy (and package
                      (project-package-macro-governance-policy package)))
         (witnesses (and policy
                         (macro-governance-policy-witnesses policy))))
    (or witnesses '())))

(def (macro-governance-contract-for macro witnesses)
  (make-macro-governance-contract
   (macro-fact-name macro)
   (macro-governance-macro-purpose macro)
   (macro-governance-macro-capabilities macro)
   (filter-map
    (lambda (entry)
      (and (equal? (car entry) (macro-fact-name macro))
           (cdr entry)))
    witnesses)))

(def (macro-governance-macro-purpose macro)
  (cond
   ((member "definition-lowering-macro"
            (macro-fact-quality-facets macro))
    'definition-lowering)
   ((member "procedural-macro-transformer"
            (macro-fact-quality-facets macro))
    'procedural-transformation)
   (else 'syntax-transformation)))

(def (macro-governance-macro-capabilities macro)
  (unique
   (append
    ['syntax-object]
    (if (member "definition-lowering-macro"
                (macro-fact-quality-facets macro))
      ['binding-introduction]
      '())
    (if (member "procedural-macro-transformer"
                (macro-fact-quality-facets macro))
      ['procedural-transformer]
      '()))))

;; Existing source-witness and expansion-IO rules are compiled into this one
;; governance plan.  They are not rerun by a second policy owner.
(def (macro-governance-findings
      index
      profile: (profile asp-strict-macro-governance-profile))
  (let (plan (macro-governance-compile-rule-plan profile))
    (append
     (if (member 'expansion-io plan)
       (macro-expansion-io-boundary-findings index)
       '())
     (if (member 'runtime-witness plan)
       (macro-runtime-source-witness-findings index)
       '())
     (macro-governance-profile-findings index profile plan: plan))))

(def (macro-governance-profile-findings
      index
      profile
      plan: (plan #f))
  (let (compiled-plan
        (or plan (macro-governance-compile-rule-plan profile)))
    (if (macro-governance-configured? index)
      (filter-map
       (lambda (macro)
         (let (reasons
               (macro-governance-profile-reason-kinds
                profile compiled-plan macro))
           (and (pair? reasons)
                (macro-governance-profile-finding profile macro reasons))))
       (macro-governance-macros index))
      '())))

(def (macro-governance-profile-reason-kinds profile plan macro)
  (filter identity
          [(and (member 'hygiene plan)
                (macro-governance-profile-require-hygiene? profile)
                (not (macro-fact-hygienic macro))
                'hygiene-required)
           (and (member 'phase plan)
                (not (member (macro-fact-phase macro)
                             (macro-governance-profile-allowed-phases
                              profile)))
                'phase-not-admitted)
           (and (member 'pattern-budget plan)
                (> (macro-fact-pattern-count macro)
                   (macro-governance-profile-max-pattern-count profile))
                'pattern-budget-exceeded)]))

(def (macro-governance-profile-finding profile macro reasons)
  (make-type-finding
   (policy-rule-id +macro-governance-admission-rule+)
   (policy-rule-severity +macro-governance-admission-rule+)
   (macro-fact-path macro)
   (string-append
    "macro " (macro-fact-name macro)
    " is rejected by macro governance profile "
    (symbol->string (macro-governance-profile-name profile)))
   (macro-fact-selector macro)
   (hash (kind "macro-governance-admission")
         (profile
          (symbol->string (macro-governance-profile-name profile)))
         (macro (macro-fact-name macro))
         (reasonKinds (map symbol->string reasons))
         (phase (macro-fact-phase macro))
         (patternCount (macro-fact-pattern-count macro))
         (hygienic (macro-fact-hygienic macro))
         (next "replace function-shaped transformers with functions, preserve syntax context, or narrow generated pattern families"))))

(def (macro-governance-admit
      index
      profile: (profile asp-strict-macro-governance-profile))
  (let* ((macros (macro-governance-macros index))
         (witnesses (macro-governance-witnesses index))
         (findings (macro-governance-findings index profile: profile))
         (decisions
          (map (lambda (macro)
                 (macro-governance-decision-for
                  macro
                  (macro-governance-contract-for macro witnesses)
                  findings))
               macros))
         (rejected
          (length
           (filter (lambda (decision)
                     (eq? (macro-governance-decision-status decision)
                          'rejected))
                   decisions)))
         (total (length decisions)))
    (make-macro-governance-receipt
     +macro-governance-admission-schema+
     "1"
     (macro-governance-profile-name profile)
     (if (zero? rejected) 'admitted 'rejected)
     total
     (- total rejected)
     rejected
     decisions)))

(def (macro-governance-decision-for macro contract findings)
  (let (reasons
        (unique
         (append-map
          (lambda (finding)
            (if (macro-governance-finding-matches? macro finding)
              (macro-governance-finding-reason-kinds finding)
              '()))
          findings)))
    (make-macro-governance-decision
     (macro-fact-name macro)
     (macro-fact-selector macro)
     (macro-governance-contract-purpose contract)
     (macro-governance-contract-capabilities contract)
     (if (null? reasons) 'admitted 'rejected)
     reasons)))

(def (macro-governance-finding-matches? macro finding)
  (let (rule-id (type-finding-rule-id finding))
    (cond
     ((equal? rule-id
              (policy-rule-id +agent-macro-expansion-io-boundary-rule+))
      (equal? (type-finding-path finding) (macro-fact-path macro)))
     (else
      (equal? (type-finding-selector finding)
              (macro-fact-selector macro))))))

(def (macro-governance-finding-reason-kinds finding)
  (let (rule-id (type-finding-rule-id finding))
    (cond
     ((equal? rule-id
              (policy-rule-id +agent-macro-expansion-io-boundary-rule+))
      ['expansion-io-denied])
     ((equal? rule-id
              (policy-rule-id +agent-macro-runtime-source-witness-rule+))
      ['executable-witness-required])
     ((equal? rule-id
              (policy-rule-id +macro-governance-admission-rule+))
      (map string->symbol
           (hash-get (type-finding-details finding) 'reasonKinds)))
     (else '()))))
