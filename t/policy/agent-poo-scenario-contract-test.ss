;;; -*- Gerbil -*-
;;; Fast scenario-level contracts for POO optimization fixtures.

(import :gerbil/gambit
        :std/test
        :asp-gerbil-scheme/src/benchmark/framework
        :policy/agent-poo-scenario-registry
        :policy/agent-poo-scenario-contract-support)

(export agent-poo-scenario-contract-test)

;; Relpath
(def +poo-scenario-contract-benchmark-root+
  "t/benchmarks/poo-scenario-contract")

;; : (-> Void)
(def (assert-poo-scenario-contracts!)
  (let ((missing-benchmarks
         (missing-poo-performance-scenario-benchmarks
          +poo-performance-scenario-ids+))
        (missing-exemptions
         (poo-performance-scenarios-missing-hot-path-exemptions
          +poo-performance-scenario-ids+))
        (missing-native-primary
         (poo-performance-scenarios-missing-native-poo-primary
          +poo-native-primary-scenario-ids+))
        (missing-native-source
         (poo-performance-scenarios-missing-native-source
          +poo-native-primary-scenario-ids+))
        (missing-optimizer-visibility
         (poo-performance-scenarios-missing-optimizer-visibility
          +poo-optimizer-visible-scenario-ids+))
        (missing-generated-boundary
         (poo-performance-scenarios-missing-generated-boundary
          +poo-generated-boundary-scenario-ids+)))
    (unless (null? missing-benchmarks)
      (error "missing POO benchmark contracts" missing-benchmarks))
    (unless (null? missing-exemptions)
      (error "missing POO hot-path exemptions" missing-exemptions))
    (unless (null? missing-native-primary)
      (error "missing POO native primary contracts" missing-native-primary))
    (unless (null? missing-native-source)
      (error "missing POO native expected source" missing-native-source))
    (unless (null? missing-optimizer-visibility)
      (error "missing POO optimizer visibility" missing-optimizer-visibility))
    (unless (null? missing-generated-boundary)
      (error "missing POO generated boundary repair contract"
             missing-generated-boundary))))

;; PolicyTest
(def agent-poo-scenario-contract-test
  (test-suite "gerbil scheme harness agent POO scenario contracts"
    (test-case "POO performance scenarios own benchmark contracts"
      (check (missing-poo-performance-scenario-benchmarks
              +poo-performance-scenario-ids+)
             => []))

    (test-case "POO performance scenarios declare hot-path exemption evidence"
      (check (poo-performance-scenarios-missing-hot-path-exemptions
              +poo-performance-scenario-ids+)
             => []))

    (test-case "POO performance scenarios keep native POO as the repair target"
      (check (poo-performance-scenarios-missing-native-poo-primary
              +poo-native-primary-scenario-ids+)
             => []))

    (test-case "POO performance scenarios project native POO into expected source"
      (check (poo-performance-scenarios-missing-native-source
              +poo-native-primary-scenario-ids+)
             => []))

    (test-case "POO optimizer-aware scenarios declare optimizer-visible repair shape"
      (check (poo-performance-scenarios-missing-optimizer-visibility
              +poo-optimizer-visible-scenario-ids+)
             => []))

    (test-case "POO generated runtime boundary scenarios prefer defstruct plus projection"
      (check (poo-performance-scenarios-missing-generated-boundary
              +poo-generated-boundary-scenario-ids+)
             => []))

    (test-case "POO scenario contract checks use benchmark.ss gate"
      (check (benchmark-contract-valid/root?
              +poo-scenario-contract-benchmark-root+)
             => #t)
      (let (receipt
            (benchmark-contract-run/root
             +poo-scenario-contract-benchmark-root+
             assert-poo-scenario-contracts!))
        (unless (benchmark-contract-receipt-pass? receipt)
          (write receipt)
          (newline))
        (check (benchmark-contract-receipt-pass? receipt) => #t)))))
