;;; -*- Gerbil -*-
;;; POO-shaped testing model for downstream Gerbil build.ss entrypoints.

(import :gerbil/gambit
        (only-in :clan/poo/object object? object<-alist .ref .slot?))

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

;; : (-> String List List MaybeInteger String TestingProject)
(def (testing-project name: (name "gerbil-project")
                      suites: (suites [])
                      roots: (roots '("t"))
                      batch-size: (batch-size #f)
                      receipt-prefix: (receipt-prefix "asp-gerbil-scheme-test"))
  (testing-object
   'testing-project
   `((name . ,name)
     (suites . ,suites)
     (roots . ,roots)
     (batchSize . ,batch-size)
     (receiptPrefix . ,receipt-prefix))))

;; : (-> String MaybePath List TestFiles List MaybeInteger MaybeInteger MaybeInteger MaybeInteger Procedure GxTestSuite)
(def (gxtest-suite name: (name "gxtest")
                   default-root: (default-root #f)
                   roots: (roots [])
                   files: (files 'auto)
                   batch-size: (batch-size #f)
                   gates: (gates [])
                   max-selected-files: (max-selected-files #f)
                   max-selected-sources: (max-selected-sources #f)
                   max-selected-outputs: (max-selected-outputs #f)
                   import->file: (import->file default-testing-import->file))
  (testing-object
   'gxtest-suite
   `((name . ,name)
     (defaultRoot . ,default-root)
     (roots . ,roots)
     (files . ,files)
     (batchSize . ,batch-size)
     (gates . ,gates)
     (maxSelectedFiles . ,max-selected-files)
     (maxSelectedSources . ,max-selected-sources)
     (maxSelectedOutputs . ,max-selected-outputs)
     (import->file . ,import->file))))

;; : (-> String List List MaybeInteger List MaybeProcedure ScenarioSuite)
(def (scenario-suite name: (name "policy-scenarios")
                     roots: (roots '("t/scenarios/policy"))
                     scenarios: (scenarios [])
                     batch-size: (batch-size #f)
                     gates: (gates [])
                     runner: (runner #f))
  (testing-object
   'scenario-suite
   `((name . ,name)
     (roots . ,roots)
     (scenarios . ,scenarios)
     (batchSize . ,batch-size)
     (gates . ,gates)
     (runner . ,runner))))

;; : (-> String Alist Procedure MaybeProcedure List PerformanceCase)
(def (performance-case name: (name "performance-case")
                       fixture: (fixture [])
                       fixture-path: (fixture-path #f)
                       runner: (runner #f)
                       runner-module: (runner-module #f)
                       runner-symbol: (runner-symbol #f)
                       validator: (validator #f)
                       validator-module: (validator-module #f)
                       validator-symbol: (validator-symbol #f)
                       details: (details []))
  (testing-object
   'performance-case
   `((name . ,name)
     (fixture . ,fixture)
     (fixturePath . ,fixture-path)
     (runner . ,runner)
     (runnerModule . ,runner-module)
     (runnerSymbol . ,runner-symbol)
     (validator . ,validator)
     (validatorModule . ,validator-module)
     (validatorSymbol . ,validator-symbol)
     (details . ,details))))

;; : (-> String List List MaybeInteger List PerformanceSuite)
(def (performance-suite name: (name "performance")
                        roots: (roots [])
                        cases: (cases [])
                        batch-size: (batch-size #f)
                        gates: (gates []))
  (testing-object
   'performance-suite
   `((name . ,name)
     (roots . ,roots)
     (cases . ,cases)
     (batchSize . ,batch-size)
     (gates . ,gates))))

;; : (-> String MaybePath MaybeContract Symbol PerformanceGate)
(def (performance-gate name: (name "performance")
                       contract-root: (contract-root #f)
                       contract: (contract #f)
                       scope: (scope 'tested-files))
  (testing-object
   'performance-gate
   `((name . ,name)
     (contractRoot . ,contract-root)
     (contract . ,contract)
     (scope . ,scope))))

;; : (-> String Symbol PolicyGate)
(def (policy-gate name: (name "policy")
                  scope: (scope 'tested-files))
  (testing-object
   'policy-gate
   `((name . ,name)
     (scope . ,scope))))

;; : (-> Symbol Symbol MaybeString List Number List List TestingReceipt)
(def (testing-receipt kind: (kind 'testing-run)
                      status: (status 'ok)
                      suite: (suite #f)
                      files: (files [])
                      elapsed-micros: (elapsed-micros 0)
                      children: (children [])
                      details: (details []))
  (testing-object
   'testing-receipt
   `((receiptKind . ,kind)
     (status . ,status)
     (suite . ,suite)
     (files . ,files)
     (elapsedMicros . ,elapsed-micros)
     (children . ,children)
     (details . ,details))))

;; : (-> MaybeTestingProject List List Symbol List TestingSelection)
(def (testing-selection project: (project #f)
                        args: (args [])
                        suites: (suites [])
                        status: (status 'ok)
                        details: (details []))
  (testing-object
   'testing-selection
   `((project . ,project)
     (args . ,args)
     (suites . ,suites)
     (status . ,status)
     (details . ,details))))

;; : (-> TestingProject String)
(def (testing-project-name project)
  (testing-object-ref project 'name))

;; : (-> TestingProject List)
(def (testing-project-suites project)
  (testing-object-ref project 'suites []))

;; : (-> TestingProject MaybeInteger)
(def (testing-project-batch-size project)
  (testing-object-ref project 'batchSize #f))

;; : (-> TestingProject String)
(def (testing-project-receipt-prefix project)
  (testing-object-ref project 'receiptPrefix "asp-gerbil-scheme-test"))

;; : (-> TestingSuite String)
(def (testing-suite-name suite)
  (testing-object-ref suite 'name))

;; : (-> TestingSuite MaybePath)
(def (testing-suite-default-root suite)
  (testing-object-ref suite 'defaultRoot #f))

;; : (-> TestingSuite List)
(def (testing-suite-roots suite)
  (testing-object-ref suite 'roots []))

;; : (-> TestingSuite TestFiles)
(def (testing-suite-files suite)
  (testing-object-ref suite 'files 'auto))

;; : (-> TestingSuite MaybeInteger)
(def (testing-suite-batch-size suite)
  (testing-object-ref suite 'batchSize #f))

;; : (-> TestingSuite List)
(def (testing-suite-gates suite)
  (testing-object-ref suite 'gates []))

;; : (-> TestingSuite MaybeInteger)
(def (testing-suite-max-selected-files suite)
  (testing-object-ref suite 'maxSelectedFiles #f))

;; : (-> TestingSuite MaybeInteger)
(def (testing-suite-max-selected-sources suite)
  (testing-object-ref suite 'maxSelectedSources #f))

;; : (-> TestingSuite MaybeInteger)
(def (testing-suite-max-selected-outputs suite)
  (testing-object-ref suite 'maxSelectedOutputs #f))

;; : (-> TestingSuite Procedure)
(def (testing-suite-import->file suite)
  (testing-object-ref suite 'import->file default-testing-import->file))

;; : (-> ScenarioSuite List)
(def (testing-scenario-suite-scenarios suite)
  (testing-object-ref suite 'scenarios []))

;; : (-> ScenarioSuite MaybeProcedure)
(def (testing-scenario-suite-runner suite)
  (testing-object-ref suite 'runner #f))

;; : (-> PerformanceSuite List)
(def (testing-performance-suite-cases suite)
  (testing-object-ref suite 'cases []))

;; : (-> PerformanceCase String)
(def (testing-performance-case-name case)
  (testing-object-ref case 'name))

;; : (-> PerformanceCase Alist)
(def (testing-performance-case-fixture case)
  (testing-object-ref case 'fixture []))

;; : (-> PerformanceCase MaybePath)
(def (testing-performance-case-fixture-path case)
  (testing-object-ref case 'fixturePath #f))

;; : (-> PerformanceCase Procedure)
(def (testing-performance-case-runner case)
  (testing-object-ref case 'runner #f))

;; : (-> PerformanceCase MaybeSymbol)
(def (testing-performance-case-runner-module case)
  (testing-object-ref case 'runnerModule #f))

;; : (-> PerformanceCase MaybeSymbol)
(def (testing-performance-case-runner-symbol case)
  (testing-object-ref case 'runnerSymbol #f))

;; : (-> PerformanceCase MaybeProcedure)
(def (testing-performance-case-validator case)
  (testing-object-ref case 'validator #f))

;; : (-> PerformanceCase MaybeSymbol)
(def (testing-performance-case-validator-module case)
  (testing-object-ref case 'validatorModule #f))

;; : (-> PerformanceCase MaybeSymbol)
(def (testing-performance-case-validator-symbol case)
  (testing-object-ref case 'validatorSymbol #f))

;; : (-> PerformanceCase List)
(def (testing-performance-case-details case)
  (testing-object-ref case 'details []))

;; : (-> TestingGate String)
(def (testing-gate-name gate)
  (testing-object-ref gate 'name))

;; : (-> TestingGate Symbol)
(def (testing-gate-scope gate)
  (testing-object-ref gate 'scope))

;; : (-> PerformanceGate MaybePath)
(def (testing-performance-gate-contract-root gate)
  (testing-object-ref gate 'contractRoot))

;; : (-> TestingReceipt Symbol)
(def (testing-receipt-status receipt)
  (testing-object-ref receipt 'status))

;; : (-> TestingReceipt Symbol)
(def (testing-receipt-kind receipt)
  (testing-object-ref receipt 'receiptKind))

;; : (-> TestingReceipt List)
(def (testing-receipt-files receipt)
  (testing-object-ref receipt 'files []))

;; : (-> TestingReceipt List)
(def (testing-receipt-children receipt)
  (testing-object-ref receipt 'children []))

;; : (-> TestingReceipt Number)
(def (testing-receipt-elapsed-micros receipt)
  (testing-object-ref receipt 'elapsedMicros 0))

;; : (-> TestingReceipt List)
(def (testing-receipt-details receipt)
  (testing-object-ref receipt 'details []))

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

;; : (-> TestingSelection MaybeTestingProject)
(def (testing-selection-project selection)
  (testing-object-ref selection 'project))

;; : (-> TestingSelection List)
(def (testing-selection-args selection)
  (testing-object-ref selection 'args []))

;; : (-> TestingSelection List)
(def (testing-selection-suites selection)
  (testing-object-ref selection 'suites []))

;; : (-> TestingSelection Symbol)
(def (testing-selection-status selection)
  (testing-object-ref selection 'status))

;; : (-> TestingSelection List)
(def (testing-selection-details selection)
  (testing-object-ref selection 'details []))

;; : (-> TestingSelection Boolean)
(def (testing-selection-ok? selection)
  (eq? (testing-selection-status selection) 'ok))

;; : (-> Datum MaybePath)
(def (default-testing-import->file import)
  (cond
   ((string? import) import)
   ((symbol? import) (symbol->string import))
   (else #f)))
