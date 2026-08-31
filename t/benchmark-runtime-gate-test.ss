;;; -*- Gerbil -*-
;;; Runtime benchmark gates for the gxtest policy library path.

(import :gerbil/gambit
        :std/test
        (only-in :asp-gerbil-scheme/src/support/time monotonic-ms duration-ms)
        (only-in :asp-gerbil-scheme/src/testing/gxtest-build compile-package-api-if-stale)
        (only-in :asp-gerbil-scheme/src/testing/gxtest-context configure-build-root!)
        (only-in :asp-gerbil-scheme/src/testing/gxtest-policy
                 scoped-policy-target-files
                 run-scoped-policy-if-stale)
        :asp-gerbil-scheme/src/benchmark/gate)

(export benchmark-runtime-gate-test)

;;; Boundary:
;;; - Scoped policy warm receipt checks should stay in the same millisecond
;;;   class as build receipts.  Cold policy can parse source; warm policy must
;;;   only verify the receipt and return.
;; : Integer
(def +scoped-policy-gate-max-warm-ms+ 50)

;; : (List Path)
(def +scoped-policy-gate-entry-files+
  ["t/build-install-test.ss"])

;; : (-> (-> Integer) Alist)
(def (run-policy-command/silent thunk)
  (let* ((start-ms (monotonic-ms))
         (status
          (parameterize ((current-output-port (open-output-string)))
            (thunk)))
         (elapsed-ms (duration-ms start-ms (monotonic-ms))))
    (list (cons 'status status)
          (cons 'elapsedMs elapsed-ms))))

;; run-policy-command/silent/best
;;   : (-> Integer (-> Integer) Alist)
;;   | doc m%
;;       `run-policy-command/silent/best attempts thunk` returns the fastest
;;       successful timing receipt from a small repeated benchmark window.
;;     %
(def (run-policy-command/silent/best attempts thunk)
  (if (<= attempts 0)
    (error "policy benchmark attempts must be positive" attempts)
    (let loop ((remaining attempts) (best #f))
      (if (zero? remaining)
        best
        (let (receipt (run-policy-command/silent thunk))
          (loop (- remaining 1)
                (if (or (not best)
                        (< (benchmark-fixture-ref receipt 'elapsedMs)
                           (benchmark-fixture-ref best 'elapsedMs)))
                  receipt
                  best)))))))

;; : (-> (List Path))
(def (scoped-policy-gate-target-files)
  (configure-build-root! (current-directory))
  (scoped-policy-target-files +scoped-policy-gate-entry-files+))

;; : (-> (List Path) Alist)
(def (run-scoped-policy/silent files)
  (run-policy-command/silent
   (lambda ()
     (run-scoped-policy-if-stale
      files
      (lambda ()
        (compile-package-api-if-stale)))
     0)))

;; : (-> (List Path) Alist)
(def (run-scoped-policy-warm/silent/best files)
  (run-policy-command/silent/best
   5
   (lambda ()
     (run-scoped-policy-if-stale files)
     0)))

;; : TestSuite
(def benchmark-runtime-gate-test
  (test-suite "gerbil scheme runtime benchmark gate"
    (test-case "gxtest scoped policy keeps selected-file boundary"
      (check (scoped-policy-gate-target-files) => +scoped-policy-gate-entry-files+)
      (check (length (scoped-policy-gate-target-files)) => 1))

    (test-case "gxtest scoped policy warm receipt stays in millisecond budget"
      (let* ((files (scoped-policy-gate-target-files))
             (cold (run-scoped-policy/silent files))
             (warm (run-scoped-policy-warm/silent/best files)))
        (check (benchmark-fixture-ref cold 'status) => 0)
        (check (benchmark-fixture-ref warm 'status) => 0)
        (check (< (benchmark-fixture-ref warm 'elapsedMs)
                  +scoped-policy-gate-max-warm-ms+)
               => #t)))))
