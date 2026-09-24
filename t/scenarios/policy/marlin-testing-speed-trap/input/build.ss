;;; -*- Gerbil -*-
(import :gerbil/runtime/gambit)

(export marlin-slow-test-target
        marlin-slow-run-log
        marlin-slow-policy-scope-count)

(def +marlin-slow-gxtest-test-files+
  '("t/deck-runtime-condition-policy-test.ss"
    "t/deck-runtime-strategy-test.ss"
    "t/deck-runtime-policy-modules-smoke-test.ss"
    "t/config-interface-driver-test.ss"
    "t/config-interface-loop-policy-pack-test.ss"
    "t/config-interface-test.ss"
    "t/marlin-policy-pack-inventory-test.ss"
    "t/deck-runtime-script-performance-test.ss"))

(def +marlin-slow-policy-scope-files+
  (append +marlin-slow-gxtest-test-files+
          '("src/config-interface/modules/policy-pack.ss"
            "src/config-interface/modules/policy-pack-core.ss"
            "src/config-interface/modules/policy-pack-presentation.ss"
            "src/config-interface/modules/policy-pack-support.ss"
            "src/config-interface/modules/policy-pack-slot-merge.ss"
            "src/config-interface/modules/policy-pack-profile-catalog.ss"
            "src/config-interface/modules/policy-pack-real-repair.ss"
            "src/config-interface/modules/policy-pack-real-policy-001.ss"
            "src/config-interface/modules/policy-pack-real-policy-basic.ss"
            "src/config-interface/modules/policy-pack-failure-combination.ss"
            "src/config-interface/modules/policy-pack-receipts.ss")))

(def +marlin-slow-gxtest-entrypoint+
  "t/all-test.ss")

(def marlin-slow-run-log [])

(def (marlin-slow-run-gxtest-main full?)
  (set! marlin-slow-run-log
        (cons `((entrypoint . ,+marlin-slow-gxtest-entrypoint+)
                (testFiles . ,(length +marlin-slow-gxtest-test-files+))
                (policyFiles . ,(length +marlin-slow-policy-scope-files+))
                (full . ,full?))
              marlin-slow-run-log))
  0)

(def (marlin-slow-test-target full?)
  (marlin-slow-run-gxtest-main full?))

(def (marlin-slow-policy-scope-count)
  (length +marlin-slow-policy-scope-files+))
