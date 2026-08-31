;;; -*- Gerbil -*-
;;; Policy scenario declarations and argument expansion for testing projects.

(import :gerbil/gambit
        (only-in :std/srfi/1 find)
        :asp-gerbil-scheme/src/testing/model
        :asp-gerbil-scheme/src/testing/scope)

(export #t)

;; : (-> String Path PolicyScenario)
(def (make-policy-scenario id root (metadata []))
  (list id root metadata))

;; : (-> PolicyScenario String)
(def (policy-scenario-id scenario)
  (list-ref scenario 0))

;; : (-> PolicyScenario Path)
(def (policy-scenario-root scenario)
  (list-ref scenario 1))

;; : (-> PolicyScenario Alist)
(def (policy-scenario-metadata scenario)
  (if (and (pair? scenario)
           (pair? (cdr scenario))
           (pair? (cddr scenario)))
    (car (cddr scenario))
    []))

;; : (-> String Path List MaybeList MaybeInteger List MaybeProcedure ScenarioSuite)
(def (policy-scenario-suite name: (name "policy-scenarios")
                            root: (root "t/scenarios/policy")
                            scenario-ids: (scenario-ids [])
                            scenarios: (scenarios #f)
                            batch-size: (batch-size #f)
                            gates: (gates [])
                            runner: (runner #f))
  (let (scenario-list
        (if scenarios
          scenarios
          (map (lambda (id)
                 (make-policy-scenario id (path-expand id root)))
               scenario-ids)))
    (scenario-suite
     name: name
     roots: (list root)
     scenarios: scenario-list
     batch-size: batch-size
     gates: gates
     runner: runner)))

;; : (-> ScenarioSuite Datum MaybePath)
(def (testing-scenario-root suite scenario)
  (cond
   ((and (pair? scenario)
         (pair? (cdr scenario)))
    (policy-scenario-root scenario))
   ((string? scenario)
    (let (roots (testing-suite-roots suite))
      (if (null? roots)
        scenario
        (path-expand scenario (car roots)))))
   (else #f)))

;; : (-> Datum String)
(def (testing-scenario-id scenario)
  (cond
   ((and (pair? scenario)
         (pair? (cdr scenario)))
    (policy-scenario-id scenario))
   ((string? scenario) scenario)
   (else "scenario")))

;; : (-> Datum Alist)
(def (testing-scenario-metadata scenario)
  (cond
   ((and (pair? scenario)
         (pair? (cdr scenario)))
    (policy-scenario-metadata scenario))
   (else [])))

;; : (-> Datum Symbol Datum)
(def (testing-scenario-metadata-ref scenario key (default #f))
  (let (entry (assq key (testing-scenario-metadata scenario)))
    (if entry (cdr entry) default)))

;; : (-> Datum Alist)
(def (testing-scenario-repair-details scenario)
  (testing-filter-map
   (lambda (key)
     (let (value (testing-scenario-metadata-ref scenario key #f))
       (and value (cons key value))))
   '(downstreamRepairTarget idiom expectedOutcome benchmarkPhases nextRepairAction)))

;; testing-declared-scenario-by-id
;;   : (-> ScenarioSuite String MaybePolicyScenario)
;;   | doc m%
;;       `testing-declared-scenario-by-id` resolves a scenario identifier from
;;       the suite declaration before falling back to path-shaped arguments.
;;
;;       # Examples
;;
;;       ```scheme
;;       (testing-declared-scenario-by-id suite "marlin-speed-trap")
;;       ;; => declared-scenario-or-#f
;;       ```
;;     %
(def (testing-declared-scenario-by-id suite id)
  (find (lambda (scenario)
          (equal? id (testing-scenario-id scenario)))
        (testing-scenario-suite-scenarios suite)))

;; : (-> ScenarioSuite Datum Datum)
(def (testing-scenario-from-arg suite arg)
  (cond
   ((and (pair? arg)
         (pair? (cdr arg)))
    arg)
   ((string? arg)
    (let (declared (testing-declared-scenario-by-id suite arg))
      (if declared
        declared
        (let ((roots (testing-suite-roots suite)))
          (cond
           ((testing-arg-under-suite-root? suite arg)
            (make-policy-scenario arg arg))
           ((null? roots)
            (make-policy-scenario arg arg))
           (else
            (make-policy-scenario arg (path-expand arg (car roots)))))))))
   (else arg)))

;; : (-> ScenarioSuite (List Datum) (List Datum))
(def (testing-expand-scenario-args suite args)
  (cond
   ((null? args)
    (testing-scenario-suite-scenarios suite))
   ((and (null? (cdr args))
         (testing-suite-root? suite (car args)))
    (testing-scenario-suite-scenarios suite))
   (else
    (map (lambda (arg)
           (testing-scenario-from-arg suite arg))
         args))))

;; : (-> ScenarioSuite Path Boolean)
(def (testing-scenario-suite-arg? suite arg)
  (or (testing-suite-root? suite arg)
      (testing-arg-under-suite-root? suite arg)
      (testing-any?
       (lambda (scenario)
         (equal? arg (testing-scenario-id scenario)))
       (testing-scenario-suite-scenarios suite))))
