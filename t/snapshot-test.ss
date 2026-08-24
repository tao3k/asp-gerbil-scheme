;;; -*- Gerbil -*-
;;; Snapshot suite facade.
;;; Individual snapshot domains live in smaller owners under t/snapshot/.

(import :std/test
  "./snapshot/evidence-test"
  "./snapshot/policy-parser-test"
  "./snapshot/protocol-test"
  "./snapshot/search-test")

(export snapshot-test)

;; SnapshotSuite
(def snapshot-test
  (test-suite "gerbil scheme harness snapshots"
    snapshot-protocol-test
    snapshot-policy-parser-test
    snapshot-search-test
    snapshot-evidence-test))
