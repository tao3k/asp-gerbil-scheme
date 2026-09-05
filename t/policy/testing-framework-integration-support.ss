;;; -*- Gerbil -*-
;;; Higher-cost fixtures for testing-framework integration and benchmark tests.

(import :gerbil/gambit
        :asp-gerbil-scheme/src/testing/model
        :asp-gerbil-scheme/src/testing/framework
        :asp-gerbil-scheme/src/testing/build
        :policy/testing-framework-support)

(export +testing-benchmark-root+
        +upstream-build-improvement-benchmark-root+
        +downstream-api-loading-scenario-root+
        +marlin-speed-trap-scenario-root+
        +upstream-gxtest-delegation-scenario-root+
        +testing-gated-suite+
        +testing-gated-scenario-suite+
        +upstream-integration-suite+
        +upstream-build-improvement-scenario-suite+
        +upstream-build-improvement-project+
        +downstream-improvement-build+
        +testing-gated-project+)

;; ConfigConstant
(def +testing-benchmark-root+
  "t/benchmarks/testing-framework")

;; ConfigConstant
(def +upstream-build-improvement-benchmark-root+
  "t/benchmarks/testing-framework-upstream-build-improvement")

;; ConfigConstant
(def +downstream-api-loading-scenario-root+
  "t/scenarios/policy/downstream-testing-framework-api-loading")

;; ConfigConstant
(def +marlin-speed-trap-scenario-root+
  "t/scenarios/policy/marlin-testing-speed-trap")

;; ConfigConstant
(def +upstream-gxtest-delegation-scenario-root+
  "t/scenarios/policy/upstream-gxtest-delegation")

;; GxTestSuite
(def +testing-gated-suite+
  (gxtest-suite
   name: "unit"
   default-root: (fixture-path "unit-tests.ss")
   roots: (list (fixture-path "unit-tests.ss"))
   batch-size: 1
   import->file: fixture-import->file
   gates: (list
           (performance-gate
            name: "testing-framework"
            contract-root: +testing-benchmark-root+))))

;; PolicyScenarioSuite
(def +testing-gated-scenario-suite+
  (policy-scenario-suite
   name: "policy-scenarios"
   root: "t/scenarios/policy"
   scenario-ids: (list "poo-construction-performance")
   batch-size: 1
   runner: fake-run-scenario
   gates: (list
           (performance-gate
            name: "poo-scenario-contract"
            contract-root: "t/benchmarks/poo-scenario-contract"))))

;; GxTestSuite
(def +upstream-integration-suite+
  (gxtest-suite
   name: "integration"
   default-root: (fixture-path "integration-tests.ss")
   roots: (list (fixture-path "integration-tests.ss"))
   batch-size: 2
   import->file: fixture-import->file
   max-selected-files: 2
   max-selected-sources: 4
   max-selected-outputs: 4))

;; PolicyScenarioSuite
(def +upstream-build-improvement-scenario-suite+
  (policy-scenario-suite
   name: "policy-scenarios-complex"
   root: "t/scenarios/policy"
   scenario-ids: (list "poo-construction-performance"
                       "poo-real-dashboard-workflow-performance")
   batch-size: 1
   runner: fake-run-scenario
   gates: (list
           (performance-gate
            name: "testing-framework-upstream-build-improvement"
            contract-root: +upstream-build-improvement-benchmark-root+))))

;; TestingProject
(def +upstream-build-improvement-project+
  (testing-project
   name: "upstream-build-improvement"
   suites: (list +testing-suite+
                 +upstream-integration-suite+
                 +upstream-build-improvement-scenario-suite+)
   roots: (list +testing-fixture-root+ "t/scenarios/policy")
   batch-size: 3
   receipt-prefix: "asp-gerbil-scheme-upstream-build-improvement"))

;; TestingBuild
(def +downstream-improvement-build+
  (testing-build
   name: "downstream-improvement"
   root: "."
   gxtest: [["unit" "t/fixtures/testing-framework/unit-tests.ss"]]
   scenario-root: "t/scenarios/policy"
   scenario-suite-name: "improvement-scenarios"
   improvement-scenarios: ["poo-construction-performance"]
   scenario-metadata:
   '(("poo-construction-performance"
      . ((downstreamRepairTarget . "poo-flow")
         (idiom . "native-poo-construction")
         (expectedOutcome . "preserve native POO object syntax while optimizing runner mechanics")
         (benchmarkPhases . ("batch-split" "scenario-root-projection"))
         (nextRepairAction . "apply the native POO construction idiom to the downstream object builder"))))))

;; TestingProject
(def +testing-gated-project+
  (testing-project
   name: "poo-flow-like-gated"
   suites: (list +testing-gated-suite+ +testing-gated-scenario-suite+)
   roots: (list +testing-fixture-root+)
   receipt-prefix: "asp-gerbil-scheme-testing-gated"))
