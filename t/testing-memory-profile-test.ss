;;; Intent:
;;; - This suite validates source-declared test memory budgets before execution.
;;; - Malformed metadata must fail closed rather than silently use unrestricted heap.
(import :gerbil/gambit
        (only-in :std/test test-suite test-case check)
        :asp-gerbil-scheme/src/testing/memory-profile)

(export testing-memory-profile-test)

;;; Boundary:
;;; - The helper turns malformed metadata into a testable boolean receipt.
;; : (-> (-> Value) Boolean)
(def (gxtest-memory-exception-raised? thunk)
  (with-catch (lambda (_exception) #t)
              (lambda ()
                (thunk)
                #f)))

(def testing-memory-profile-test
  (test-suite "gxtest memory profile"
    (test-case "parses a bounded managed-heap declaration"
      (let* ((fixture "t/fixtures/testing-memory-profile/profile.ss")
             (max-heap-mib (gxtest-file-memory-max-heap-mib fixture))
                 (exception? (gxtest-file-memory-exception? fixture))
             (runtime-options (gxtest-file-memory-runtime-options fixture)))
          (check max-heap-mib => 96)
          (check exception? => #t)
          (check runtime-options => ["-:max-heap=96M"])))
    (test-case "rejects a malformed memory exception declaration"
      (let (fixture "t/fixtures/testing-memory-profile/invalid-profile.ss")
        (check
         (gxtest-memory-exception-raised?
          (lambda ()
            (gxtest-file-memory-max-heap-mib fixture)))
         => #t)))
    (test-case "rejects a nonliteral memory exception declaration"
      (let (fixture "t/fixtures/testing-memory-profile/nonliteral-profile.ss")
        (check
         (gxtest-memory-exception-raised?
          (lambda ()
            (gxtest-file-memory-max-heap-mib fixture)))
         => #t)))))
