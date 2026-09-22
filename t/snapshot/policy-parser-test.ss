;;; -*- Gerbil -*-
;;; Parser and policy snapshot checks.

(import :std/test
        "../unit/snapshot/parser"
        "../unit/snapshot/policy"
        "../unit/snapshot/check-report"
        "../unit/snapshot/self-apply")

(export snapshot-policy-parser-test)

;; SnapshotSuite
(def snapshot-policy-parser-test
  (test-suite "parser and policy snapshots"
    (test-case "parser snapshot fixtures cover complex native syntax facts"
      (check-parser-complex-native-facts-snapshot))
    (test-case "policy snapshot fixtures cover downstream POO agent drift"
      (check-policy-snapshot-fixtures))
    (test-case "check report snapshot uses stable unit interface"
      (check-empty-check-report-snapshot))
    (test-case "self apply findings snapshot is an explicit invariant"
      (check-empty-self-apply-findings-snapshot))))
