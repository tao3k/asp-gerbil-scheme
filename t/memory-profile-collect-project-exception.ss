;;; -*- Gerbil -*-

(import :gerbil/gambit
        :std/test
        :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/testing/memory-profile)

(export memory-profile-collect-project-exception-test)

(declare-gxtest-memory-exception
 '((maxHeapMiB . 512)))

(def memory-profile-collect-project-exception-test
  (test-suite "gxtest memory profile project-index exception"
    (test-case "bounds repeated fixture profile materialization"
      (let loop ((iteration 0) (expected-definition-count #f))
        (when (< iteration 32)
          (let* ((receipt
                  (collect-project/profile
                   "t/scenarios/policy/parser-combinator-boundary/input"))
                 (profile (hash-get receipt 'profile))
                 (definition-count (hash-get profile 'definitionCount)))
            (check (> (hash-get profile 'fileCount) 0) => #t)
            (check (number? definition-count) => #t)
            (when expected-definition-count
              (check definition-count => expected-definition-count))
            (check (list? (hash-get profile 'slowestFiles)) => #t)
            (##gc)
            (loop (+ iteration 1)
                  (or expected-definition-count definition-count))))))))
