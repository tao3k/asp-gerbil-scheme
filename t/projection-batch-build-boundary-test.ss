;;; -*- Gerbil -*-
;;; Regression gate: exact-owner projection stays outside the full parser graph.

(import (only-in :gslph/src/testing/gxtest-sources
                 gxtest-selected-source-files)
        :std/test)

(export projection-batch-build-boundary-test)

(def +projection-batch-heavy-modules+
  '("src/parser/facade.ss"
    "src/parser/core.ss"
    "src/parser/source-file.ss"
    "src/parser/syntax.ss"
    "src/protocol/json.ss"))

(def projection-batch-build-boundary-test
  (test-suite
   "Gerbil projection batch build boundary"
   (test-case
    "selected projection test excludes the full parser and JSON projection graph"
    (let (files
          (gxtest-selected-source-files
           '("t/projection-batch-test.ss")))
      (check (<= (length files) 16) => #t)
      (for-each
       (lambda (heavy-module)
         (check (member heavy-module files) => #f))
       +projection-batch-heavy-modules+)))))
