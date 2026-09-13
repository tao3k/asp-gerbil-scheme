;;; -*- Gerbil -*-
(import :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/snapshot/facade
        :std/test)

(export check-parser-complex-native-facts-snapshot)
;; Snapshot
(def (check-parser-complex-native-facts-snapshot)
  (let (file (parse-source-file "." "t/fixtures/parser/complex-syntax.ss"))
    (check (parser-source-file-snapshot file)
           => (snapshot-load "t/snapshots/parser-complex-native-facts.ss"))))
