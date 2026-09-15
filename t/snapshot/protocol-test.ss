;;; -*- Gerbil -*-
;;; Protocol snapshot checks.

(import :std/test
        :unit/snapshot/extension-test
        :unit/snapshot/language-evidence)

(export snapshot-protocol-test)

;; SnapshotSuite
(def snapshot-protocol-test
  (test-suite "protocol snapshots"
    (test-case "provider extension snapshot uses schema field names"
      (check-extension-snapshot-schema-fields))
    (test-case "guide and registry expose provider-native facts without search methods"
      (check-guide-and-registry-fact-boundary))))
