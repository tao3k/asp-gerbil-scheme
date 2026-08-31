;;; -*- Gerbil -*-
(import :gerbil/gambit
        :asp-gerbil-scheme/src/testing/build
        :asp-gerbil-scheme/src/testing/build-runner)

(export downstream-testing-project
        downstream-testing-main)

(def +downstream-scenario-root+
  "t/scenarios/policy/downstream-testing-framework-api-loading/input")

(def downstream-testing-project
  (testing-build
   name: "downstream-api-loading"
   root: +downstream-scenario-root+
   contract-root: "t/scenarios/policy/downstream-testing-framework-api-loading"
   gxtest: [["unit" "t/unit-tests.ss"]
            ["scenario-a" "t/scenario-a-test.ss"]
            ["scenario-b" "t/scenario-b-test.ss"]
            ["performance" "t/performance-test.ss"]]
   scenarios: ["style-large-object"]
   scenario-suite-name: "policy"
   roots: ["src" "t" "policy-scenarios"]))

(def (downstream-testing-main args (run-files #f))
  (testing-build-main downstream-testing-project args run-files))
