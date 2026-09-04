;;; -*- Gerbil -*-
;;; Intent:
;;; - This suite protects the parser's repeated-project memory boundary.
;;; - The runner reads its declaration before execution and applies the heap cap.
(import (only-in :gerbil/gambit getenv setenv)
        (only-in :std/test test-suite test-case check)
        (only-in :std/srfi/1 iota)
        (only-in :std/srfi/13 string-prefix? string-split)
        (only-in :std/misc/path path-expand)
        (only-in :std/sort sort)
        :asp-gerbil-scheme/src/parser/core
        :asp-gerbil-scheme/src/parser/profile
        (only-in :asp-gerbil-scheme/src/policy/gxtest-report
                 policy-source-report)
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

;; : (forall (A) (-> String (-> A) A))
(def (with-parser-trace value thunk)
  (let (previous (getenv "ASP_GERBIL_SCHEME_PARSE_TRACE" #f))
    (dynamic-wind
      (lambda () (setenv "ASP_GERBIL_SCHEME_PARSE_TRACE" value))
      thunk
      (lambda ()
        (if previous
          (setenv "ASP_GERBIL_SCHEME_PARSE_TRACE" previous)
          (setenv "ASP_GERBIL_SCHEME_PARSE_TRACE"))))))

;; : (-> (List String) (List String))
(def (policy-parse-start-lines files)
  (let (output
        (call-with-output-string
         (lambda (out)
           (parameterize ((current-output-port out))
             (with-parser-trace
              "1"
              (lambda ()
                (policy-source-report "." files)))))))
    (sort
     (filter (cut string-prefix?
                  "[asp-gerbil-scheme-parse-worker] event=start path=" <>)
             (string-split output #\newline))
     string<?)))

;; : (-> (List String) (List String))
(def (expected-policy-parse-start-lines files)
  (sort
   (map (cut string-append
             "[asp-gerbil-scheme-parse-worker] event=start path=" <>)
        (map (cut path-expand <> (current-directory)) files))
   string<?))

;;; Boundary:
;;; - The repeated profile test compares parser facts without retaining source receipts.
;; : TestSuite
(def parser-memory-stability-test
  (test-suite "parser profile memory stability"
    (test-case "uses available parser concurrency without a fixed host cap"
      (check (collect-project-default-worker-count 277 12) => 12)
      (check (collect-project-default-worker-count 3 12) => 3))
    (test-case "parses each policy owner exactly once"
      (let (files ["t/fixtures/parser/boolean-condition.ss"
                   "t/fixtures/parser/poo-method-dispatch.ss"
                   "t/fixtures/parser/poo-trie-descriptor.ss"])
        (check (policy-parse-start-lines files)
               =>
               (expected-policy-parse-start-lines files))))
    (test-case "releases repeated fixture profile receipts"
      (let ((counts (parser-profile-definition-counts)))
        (for-each (lambda (definition-count)
                    (check definition-count => (car counts)))
                  (cdr counts))))))
