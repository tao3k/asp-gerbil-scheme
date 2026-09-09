;;; -*- Gerbil -*-
;;; POO-shaped testing model for downstream Gerbil build.ss entrypoints.

(import :gerbil/gambit
        (only-in :clan/poo/object object? object<-alist .ref .slot?)
        (only-in "../object-family/syntax" defpoo-object-family))

(export #t)

;; : (-> Symbol Alist TestingObject)
(def (testing-object kind fields)
  (object<-alist (cons (cons 'kind kind) fields)))

;; : (-> Procedure TestingLazy)
(def (testing-lazy thunk)
  (unless (procedure? thunk)
    (error "testing-lazy expects a thunk" thunk))
  (testing-object 'testing-lazy
                  `((state . ,(vector #f thunk)))))

;; : (-> Symbol Alist Procedure TestingLazy)
(def (testing-lazy-object kind fields thunk)
  (unless (procedure? thunk)
    (error "testing-lazy-object expects a thunk" thunk))
  (testing-object
   'testing-lazy
   (append `((lazyKind . ,kind)
             (state . ,(vector #f thunk)))
           fields)))

;; : (-> Datum Boolean)
(def (testing-lazy? value)
  (and (object? value)
       (.slot? value 'kind)
       (eq? (.ref value 'kind) 'testing-lazy)))

;; : (-> Datum Datum)
(def (testing-force value)
  (if (testing-lazy? value)
    (let (state (.ref value 'state))
      (if (vector-ref state 0)
        (vector-ref state 1)
        (let (forced ((vector-ref state 1)))
          (vector-set! state 0 #t)
          (vector-set! state 1 forced)
          forced)))
    value))

;; : (-> Symbol POOObject (List Symbol) TestingObject)
(def (testing-native-poo-object kind source fields)
  (unless (object? source)
    (error "testing-native-poo-object expects a POO object" source))
  (testing-object
   kind
   (map (lambda (field)
          (cons field (.ref source field)))
        fields)))

;; : (-> TestingObject Symbol)
(def (testing-object-kind object)
  (if (testing-lazy? object)
    (testing-object-ref object 'lazyKind 'testing-lazy)
    (testing-object-ref object 'kind)))

;; : (-> Datum POOObject)
(def (testing-force-object object)
  (let (forced (testing-force object))
    (unless (object? forced)
      (error "testing-object-ref expects a POO object" forced))
    forced))

;; : (-> POOObject Symbol Datum Datum)
(def (testing-poo-slot-ref object key default)
  (testing-force
   (if (.slot? object key)
     (.ref object key)
     default)))

;; : (-> TestingLazy Symbol Datum Datum)
(def (testing-lazy-object-ref object key default)
  (if (.slot? object key)
    (testing-force (.ref object key))
    (testing-object-ref (testing-force object) key default)))

;; : (-> TestingObject Symbol Datum)
(def (testing-object-ref object key (default #f))
  (if (testing-lazy? object)
    (testing-lazy-object-ref object key default)
    (testing-poo-slot-ref (testing-force-object object) key default)))

;;; Stable public testing families are declared once.  Each declaration expands
;;; to a native POO prototype, its existing keyword constructor, and lazy-aware
;;; accessors.  Dynamic field intake remains in testing-object and
;;; testing-lazy-object as the explicit alist adapter boundary.
(defpoo-object-family
  (prototype testing-project-prototype (kind 'testing-project))
  (constructor
   (testing-project name: (project-name "gerbil-project")
                    suites: (project-suites [])
                    roots: (project-roots '("t"))
                    batch-size: (project-batch-size #f)
                    receipt-prefix:
                    (project-receipt-prefix "asp-gerbil-scheme-test"))
   (name project-name)
   (suites project-suites)
   (roots project-roots)
   (batchSize project-batch-size)
   (receiptPrefix project-receipt-prefix))
  (accessors testing-object-ref
             (required (testing-project-name name))
             (optional
              (testing-project-suites suites [])
              (testing-project-batch-size batchSize #f)
              (testing-project-receipt-prefix
               receiptPrefix "asp-gerbil-scheme-test"))))

(defpoo-object-family
  (prototype gxtest-suite-prototype (kind 'gxtest-suite))
  (constructor
   (gxtest-suite name: (suite-name "gxtest")
                 default-root: (suite-default-root #f)
                 roots: (suite-roots [])
                 files: (suite-files 'auto)
                 batch-size: (suite-batch-size #f)
                 gates: (suite-gates [])
                 max-selected-files: (suite-max-selected-files #f)
                 max-selected-sources: (suite-max-selected-sources #f)
                 max-selected-outputs: (suite-max-selected-outputs #f)
                 import->file:
                 (suite-import->file default-testing-import->file))
   (name suite-name)
   (defaultRoot suite-default-root)
   (roots suite-roots)
   (files suite-files)
   (batchSize suite-batch-size)
   (gates suite-gates)
   (maxSelectedFiles suite-max-selected-files)
   (maxSelectedSources suite-max-selected-sources)
   (maxSelectedOutputs suite-max-selected-outputs)
   (import->file suite-import->file))
  (accessors testing-object-ref
             (required (testing-suite-name name))
             (optional
              (testing-suite-default-root defaultRoot #f)
              (testing-suite-roots roots [])
              (testing-suite-files files 'auto)
              (testing-suite-batch-size batchSize #f)
              (testing-suite-gates gates [])
              (testing-suite-max-selected-files maxSelectedFiles #f)
              (testing-suite-max-selected-sources maxSelectedSources #f)
              (testing-suite-max-selected-outputs maxSelectedOutputs #f)
              (testing-suite-import->file
               import->file default-testing-import->file))))

(defpoo-object-family
  (prototype scenario-suite-prototype (kind 'scenario-suite))
  (constructor
   (scenario-suite name: (scenario-suite-name "policy-scenarios")
                   roots: (scenario-suite-roots '("t/scenarios/policy"))
                   scenarios: (scenario-suite-scenarios [])
                   batch-size: (scenario-suite-batch-size #f)
                   gates: (scenario-suite-gates [])
                   runner: (scenario-suite-runner #f))
   (name scenario-suite-name)
   (roots scenario-suite-roots)
   (scenarios scenario-suite-scenarios)
   (batchSize scenario-suite-batch-size)
   (gates scenario-suite-gates)
   (runner scenario-suite-runner))
  (accessors testing-object-ref
             (required)
             (optional
              (testing-scenario-suite-scenarios scenarios [])
              (testing-scenario-suite-runner runner #f))))

(defpoo-object-family
  (prototype performance-case-prototype (kind 'performance-case))
  (constructor
   (performance-case name: (case-name "performance-case")
                     fixture: (case-fixture [])
                     fixture-path: (case-fixture-path #f)
                     runner: (case-runner #f)
                     runner-module: (case-runner-module #f)
                     runner-symbol: (case-runner-symbol #f)
                     validator: (case-validator #f)
                     validator-module: (case-validator-module #f)
                     validator-symbol: (case-validator-symbol #f)
                     details: (case-details []))
   (name case-name)
   (fixture case-fixture)
   (fixturePath case-fixture-path)
   (runner case-runner)
   (runnerModule case-runner-module)
   (runnerSymbol case-runner-symbol)
   (validator case-validator)
   (validatorModule case-validator-module)
   (validatorSymbol case-validator-symbol)
   (details case-details))
  (accessors testing-object-ref
             (required (testing-performance-case-name name))
             (optional
              (testing-performance-case-fixture fixture [])
              (testing-performance-case-fixture-path fixturePath #f)
              (testing-performance-case-runner runner #f)
              (testing-performance-case-runner-module runnerModule #f)
              (testing-performance-case-runner-symbol runnerSymbol #f)
              (testing-performance-case-validator validator #f)
              (testing-performance-case-validator-module validatorModule #f)
              (testing-performance-case-validator-symbol validatorSymbol #f)
              (testing-performance-case-details details []))))

(defpoo-object-family
  (prototype performance-suite-prototype (kind 'performance-suite))
  (constructor
   (performance-suite name: (performance-suite-name "performance")
                      roots: (performance-suite-roots [])
                      cases: (performance-suite-cases [])
                      batch-size: (performance-suite-batch-size #f)
                      gates: (performance-suite-gates []))
   (name performance-suite-name)
   (roots performance-suite-roots)
   (cases performance-suite-cases)
   (batchSize performance-suite-batch-size)
   (gates performance-suite-gates))
  (accessors testing-object-ref
             (required)
             (optional (testing-performance-suite-cases cases []))))

(defpoo-object-family
  (prototype performance-gate-prototype (kind 'performance-gate))
  (constructor
   (performance-gate name: (gate-name "performance")
                     contract-root: (gate-contract-root #f)
                     contract: (gate-contract #f)
                     scope: (gate-scope 'tested-files))
   (name gate-name)
   (contractRoot gate-contract-root)
   (contract gate-contract)
   (scope gate-scope))
  (accessors testing-object-ref
             (required
              (testing-gate-name name)
              (testing-gate-scope scope)
              (testing-performance-gate-contract-root contractRoot))
             (optional)))

(defpoo-object-family
  (prototype policy-gate-prototype (kind 'policy-gate))
  (constructor
   (policy-gate name: (gate-name "policy")
                scope: (gate-scope 'tested-files))
   (name gate-name)
   (scope gate-scope))
  (accessors testing-object-ref (required) (optional)))

(defpoo-object-family
  (prototype testing-receipt-prototype (kind 'testing-receipt))
  (constructor
   (testing-receipt kind: (receipt-kind 'testing-run)
                    status: (receipt-status 'ok)
                    suite: (receipt-suite #f)
                    files: (receipt-files [])
                    elapsed-micros: (receipt-elapsed-micros 0)
                    children: (receipt-children [])
                    details: (receipt-details []))
   (receiptKind receipt-kind)
   (status receipt-status)
   (suite receipt-suite)
   (files receipt-files)
   (elapsedMicros receipt-elapsed-micros)
   (children receipt-children)
   (details receipt-details))
  (accessors testing-object-ref
             (required
              (testing-receipt-status status)
              (testing-receipt-kind receiptKind))
             (optional
              (testing-receipt-files files [])
              (testing-receipt-children children [])
              (testing-receipt-elapsed-micros elapsedMicros 0)
              (testing-receipt-details details []))))

(defpoo-object-family
  (prototype testing-selection-prototype (kind 'testing-selection))
  (constructor
   (testing-selection project: (selection-project #f)
                      args: (selection-args [])
                      suites: (selection-suites [])
                      status: (selection-status 'ok)
                      details: (selection-details []))
   (project selection-project)
   (args selection-args)
   (suites selection-suites)
   (status selection-status)
   (details selection-details))
  (accessors testing-object-ref
             (required
              (testing-selection-project project)
              (testing-selection-status status))
             (optional
              (testing-selection-args args [])
              (testing-selection-suites suites [])
              (testing-selection-details details []))))

;; : (-> TestingReceipt Symbol Datum Datum)
(def (testing-receipt-detail receipt key default: (default #f))
  (let (entry (assq key (testing-receipt-details receipt)))
    (if entry (cdr entry) default)))

;; : (-> TestingReceipt List)
(def (testing-receipt-phases receipt)
  (let (entry (assq 'phases (testing-receipt-details receipt)))
    (if entry (cdr entry) [])))

;; : (-> TestingReceipt Boolean)
(def (testing-receipt-ok? receipt)
  (eq? (testing-receipt-status receipt) 'ok))

;; : (-> TestingSelection Boolean)
(def (testing-selection-ok? selection)
  (eq? (testing-selection-status selection) 'ok))

;; : (-> Datum MaybePath)
(def (default-testing-import->file import)
  (cond
   ((string? import) import)
   ((symbol? import) (symbol->string import))
   (else #f)))
