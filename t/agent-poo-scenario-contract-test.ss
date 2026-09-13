;;; Intent:
;;; - This test owns the correspondence between registered POO scenarios and benchmark witnesses.
;;; - Keep the registry-facing paths stable so policy coverage cannot silently lose a representative case.
(import
 :gerbil/gambit
 (only-in :std/test test-suite test-case check)
 (only-in :std/misc/path path-expand)
 (only-in :std/sugar filter-map)
 :asp-gerbil-scheme/t/policy/agent-poo-scenario-registry)

(export agent-poo-scenario-contract-test)

(def +representative-poo-scenario+
  "poo-marlin-config-interface-large-object-performance")

;;; Boundary:
;;; - Benchmark paths stay rooted at policy scenarios to catch registration drift.
;; : (-> ScenarioId Path)
(def (scenario-benchmark-path scenario-id)
  (path-expand "benchmark.ss" (path-expand scenario-id "t/scenarios/policy")))

;;; Invariant:
;;; - Every POO performance scenario has a checked-in benchmark witness.
;; : (-> (List ScenarioId) (List Path))
(def (missing-scenario-benchmarks scenario-ids)
  (filter-map (lambda (scenario-id)
                (let (path (scenario-benchmark-path scenario-id))
                  (and (not (file-exists? path)) path)))
              scenario-ids))

;;; Intent:
;;; - Keep native scenario registry coverage aligned with benchmark ownership.
;; : TestSuite
(def agent-poo-scenario-contract-test
  (test-suite
   "gerbil scheme harness agent POO scenario smoke"
   (test-case
    "POO performance scenarios own benchmark files"
    (check (missing-scenario-benchmarks +poo-performance-scenario-ids+) => (@list)))
   (test-case
    "representative POO scenario is covered by native POO registry"
    (check (member +representative-poo-scenario+
                   +poo-native-primary-scenario-ids+)
           ? true)
    (check (member +representative-poo-scenario+
                   +poo-optimizer-visible-scenario-ids+)
           ? true))))
