;;; -*- Gerbil -*-
(import :gerbil/gambit
        :asp-gerbil-scheme/build-api)

(export marlin-speed-project
        marlin-speed-main)

(def +marlin-speed-scenario-root+
  "t/scenarios/policy/marlin-testing-speed-trap/expected")

(def marlin-speed-project
  (testing-build
   name: "marlin-testing-speed-trap"
   root: +marlin-speed-scenario-root+
   contract-root: "t/scenarios/policy/marlin-testing-speed-trap"
   gxtest: [["deck-runtime" "t/deck-runtime-tests.ss"]
            ["config-interface" "t/config-interface-tests.ss"]]
   scenarios: ["large-config-object"
               "policy-pack-routing"]
   roots: ["src" "t" "policy-scenarios"]))

(def (marlin-speed-main args (run-files #f))
  (testing-build-main marlin-speed-project args run-files))
