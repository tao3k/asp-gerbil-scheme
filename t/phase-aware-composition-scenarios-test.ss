;;; -*- Gerbil -*-

(import :std/test
        :asp-gerbil-scheme/src/parser/model
        :asp-gerbil-scheme/src/scenario/benchmark-contract
        :asp-gerbil-scheme/src/scenario/policy)

(def +composition-hygiene-scenario+
  "t/scenarios/policy/macro-hygiene-context-preservation")
(def +composition-hygiene-benchmark+
  "t/scenarios/policy/macro-hygiene-context-preservation/benchmark.ss")

(def +composition-phase-split-scenario+
  "t/scenarios/policy/phase-aware-helper-split")
(def +composition-phase-split-benchmark+
  "t/scenarios/policy/phase-aware-helper-split/benchmark.ss")

(def +composition-single-instantiation-scenario+
  "t/scenarios/policy/single-instantiation-composition-expansion")
(def +composition-single-instantiation-benchmark+
  "t/scenarios/policy/single-instantiation-composition-expansion/benchmark.ss")

(def (composition-scenario-run scenario-root)
  (policy-scenario-run/checks
   (make-policy-scenario "." scenario-root)))

(def (composition-scenario-source-file index)
  (let loop ((rest (project-index-files index)))
    (cond
     ((null? rest)
      (error "composition scenario has no Scheme source owner"))
     ((pair? (source-file-definitions (car rest)))
      (car rest))
     (else
      (loop (cdr rest))))))

(def (composition-scenario-call? source callee)
  (let loop ((rest (source-file-calls source)))
    (and (pair? rest)
         (or (string=? (call-fact-callee (car rest)) callee)
             (loop (cdr rest))))))

(def (composition-scenario-phase-import?
      source
      module-name
      phase
      modifier)
  (let loop ((rest (source-file-module-imports source)))
    (and (pair? rest)
         (let (import-fact (car rest))
           (or (and (string=?
                     (module-import-fact-module import-fact)
                     module-name)
                    (string=?
                     (module-import-fact-phase import-fact)
                     phase)
                    (string=?
                     (module-import-fact-modifier import-fact)
                     modifier))
               (loop (cdr rest)))))))

(def (composition-scenario-feature benchmark-path)
  (hash-get
   (scenario-benchmark-contract/path
    "."
    benchmark-path)
   'feature))

(def phase-aware-composition-scenarios-tests
  (test-suite
   "phase-aware composition policy scenarios"
   (test-case
    "hygiene scenario preserves syntax identity facts"
    (let* ((result
            (composition-scenario-run
             +composition-hygiene-scenario+))
           (input
            (composition-scenario-source-file (list-ref result 1)))
           (expected
            (composition-scenario-source-file (list-ref result 2))))
      (check-equal?
       (composition-scenario-feature
        +composition-hygiene-benchmark+)
       "macro-hygiene-context-preservation")
      (check-equal? (composition-scenario-call? input "syntax->datum") #t)
      (check-equal? (composition-scenario-call? input "symbol->string") #t)
      (check-equal?
       (composition-scenario-call? expected "free-identifier=?")
       #t)
      (check-equal? (composition-scenario-call? expected "syntax->datum")
                    #f)))
   (test-case
    "phase split scenario records the syntax import boundary"
    (let* ((result
            (composition-scenario-run +composition-phase-split-scenario+))
           (expected
            (composition-scenario-source-file (list-ref result 2))))
      (check-equal?
       (composition-scenario-feature +composition-phase-split-benchmark+)
       "phase-aware-helper-split")
      (check-equal?
       (composition-scenario-phase-import?
        expected
        ":poo-flow/module-system/profile-composition-syntax-plan"
        "syntax"
        "for-syntax")
       #t)))
   (test-case
    "single-instantiation scenario rejects source loading"
    (let* ((result
            (composition-scenario-run
             +composition-single-instantiation-scenario+))
           (input
            (composition-scenario-source-file (list-ref result 1)))
           (expected
            (composition-scenario-source-file (list-ref result 2))))
      (check-equal?
       (composition-scenario-feature
        +composition-single-instantiation-benchmark+)
       "single-instantiation-composition-expansion")
      (check-equal? (composition-scenario-call? input "load") #t)
      (check-equal? (composition-scenario-call? input "set!") #t)
      (check-equal? (composition-scenario-call? expected "load") #f)
      (check-equal?
       (composition-scenario-phase-import?
        expected
        ":poo-flow/module-system/profile-composition-syntax-plan"
        "syntax"
        "for-syntax")
       #t)))))

(run-tests! phase-aware-composition-scenarios-tests)
