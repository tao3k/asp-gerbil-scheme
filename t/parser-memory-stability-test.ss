;;; -*- Gerbil -*-
;;; Intent:
;;; - This suite protects the parser's repeated-project memory boundary.
;;; - The runner reads its declaration before execution and applies the heap cap.
(import (only-in :std/test test-suite test-case check)
        (only-in :std/srfi/1 iota)
        :asp-gerbil-scheme/src/parser/core
        :asp-gerbil-scheme/src/parser/profile
        (only-in :asp-gerbil-scheme/src/testing/memory-profile
                 declare-gxtest-memory-exception))

(export parser-memory-stability-test)

(declare-gxtest-memory-exception
 '((maxHeapMiB . 512)))

;;; Boundary:
;;; - Map owns fixed repetition while each receipt is released before the next input.
;; : (-> Void (List Integer))
(def (parser-profile-definition-counts)
  (map (lambda (_iteration)
         (let* ((receipt
                 (collect-project/profile
                  "t/scenarios/policy/parser-combinator-boundary/input"))
                (profile (hash-get receipt 'profile))
                (definition-count (hash-get profile 'definitionCount))
                (slowest-files (hash-get profile 'slowestFiles)))
           (check definition-count ? integer?)
           (check (<= (length slowest-files) 10) => #t)
           (##gc)
           definition-count))
       (iota 32)))

;;; Boundary:
;;; - The repeated profile test compares parser facts without retaining source receipts.
;; : TestSuite
(def parser-memory-stability-test
  (test-suite "parser profile memory stability"
    (test-case "caps default parser concurrency below full source packet pressure"
      (check (collect-project-default-worker-count 277 12) => 4)
      (check (collect-project-default-worker-count 3 12) => 3))
    (test-case "releases repeated fixture profile receipts"
      (let ((counts (parser-profile-definition-counts)))
        (for-each (lambda (definition-count)
                    (check definition-count => (car counts)))
                  (cdr counts))))))
