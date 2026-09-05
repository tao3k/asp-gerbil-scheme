;;; -*- Gerbil -*-
;;; Shared fixtures for testing-framework policy tests.

;;; Boundary:
;;; - This module owns the low-cost fixture paths, POO-shaped testing projects,
;;;   and receipt selectors used by the core policy testing framework suite.
;;; - Benchmark, downstream build, and other high-cost integration fixtures live
;;;   in testing-framework-integration-support.ss.

(import :gerbil/gambit
        (only-in :std/srfi/1 find)
        (only-in :clan/poo/object .o)
        :asp-gerbil-scheme/src/testing/model
        :asp-gerbil-scheme/src/testing/framework)

(export +testing-fixture-root+
        fixture-path
        fixture-import->file
        fake-run-files
        fake-run-scenario
        testing-details-ref
        testing-selection-detail
        testing-test-phase-names
        testing-test-phase-name
        testing-test-phase
        +fake-native-poo-testing-project+
        +testing-project-from-native-poo+
        +testing-suite+
        +testing-scenario-suite+
        +testing-project+)

;; ConfigConstant
(def +testing-fixture-root+
  "t/fixtures/testing-framework")

;; : (-> Path Path)
(def (fixture-path file)
  (path-expand file +testing-fixture-root+))

;; : (-> Path Path)
(def (fixture-import->file import)
  (path-expand import +testing-fixture-root+))

;; : (-> (List Path) Integer)
(def (fake-run-files files)
  0)

;; : (-> PolicyScenario PolicyScenario)
(def (fake-run-scenario scenario)
  scenario)

;; : (-> Alist Symbol Value)
(def (testing-details-ref details key)
  (cdr (assq key details)))

;; : (-> TestingSelection Symbol Value)
(def (testing-selection-detail selection key)
  (testing-details-ref (testing-selection-details selection) key))

;; : (-> TestingReceipt (List Symbol))
(def (testing-test-phase-names receipt)
  (map testing-test-phase-name (testing-receipt-phases receipt)))

;; : (-> TestingReceipt Symbol)
(def (testing-test-phase-name phase)
  (testing-receipt-detail phase 'phase))

;; : (-> TestingReceipt Symbol MaybeTestingReceipt)
(def (testing-test-phase receipt phase-name)
  (find (lambda (phase)
          (eq? (testing-test-phase-name phase) phase-name))
        (testing-receipt-phases receipt)))

;; NativePooTestingProject
(def +fake-native-poo-testing-project+
  (.o (name "native-poo-project")
      (suites [])
      (roots ["t"])
      (batchSize 2)
      (receiptPrefix "native-poo")))

;; TestingProject
(def +testing-project-from-native-poo+
  (testing-native-poo-object
   'testing-project
   +fake-native-poo-testing-project+
   '(name suites roots batchSize receiptPrefix)))

;; GxTestSuite
(def +testing-suite+
  (gxtest-suite
   name: "unit"
   default-root: (fixture-path "unit-tests.ss")
   roots: (list (fixture-path "unit-tests.ss"))
   batch-size: 1
   import->file: fixture-import->file))

;; PolicyScenarioSuite
(def +testing-scenario-suite+
  (policy-scenario-suite
   name: "policy-scenarios"
   root: "t/scenarios/policy"
   scenario-ids: (list "poo-construction-performance")
   batch-size: 1
   runner: fake-run-scenario))

;; TestingProject
(def +testing-project+
  (testing-project
   name: "poo-flow-like"
   suites: (list +testing-suite+ +testing-scenario-suite+)
   roots: (list +testing-fixture-root+)
   receipt-prefix: "asp-gerbil-scheme-testing"))
