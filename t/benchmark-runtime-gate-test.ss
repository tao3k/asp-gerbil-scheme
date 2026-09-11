;;; -*- Gerbil -*-
;;; Runtime benchmark gates for the gxtest policy library path.

(import :gerbil/gambit
        :std/test
        (only-in :clan/timestamp call-with-timing)
        (only-in :asp-gerbil-scheme/src/benchmark/statistics
                 benchmark-sample-statistics
                 benchmark-select-sample)
        (only-in :asp-gerbil-scheme/src/support/time
                 duration-literal->nanos
                 duration-nanos->text)
        (only-in :asp-gerbil-scheme/src/testing/gxtest-build compile-package-api-if-stale)
        (only-in :asp-gerbil-scheme/src/testing/gxtest-context configure-build-root!)
        (only-in :asp-gerbil-scheme/src/testing/gxtest-policy
                 scoped-policy-target-files
                 run-scoped-policy-if-stale)
        :asp-gerbil-scheme/src/benchmark/gate)

(export benchmark-runtime-gate-test)

;;; Boundary:
;;; - Requested files remain a report projection over the Build API declared
;;;   Production Graph and Testing Graph.
;;; - Scoped policy warm receipt checks should stay inside an exact duration
;;;   budget. Cold policy can parse source; warm policy must only verify the
;;;   receipt and return.
;; The warm gate retains twenty samples so nearest-rank p95 is distinct from
;; the maximum. Keep a 200ms objective and explicit 200ms regression headroom;
;; the p95 receipt still exposes target misses below the hard ceiling.
;; : DurationLiteral
(def +scoped-policy-gate-target-warm+ '200ms)
;; : DurationLiteral
(def +scoped-policy-gate-regression-warm+ '200ms)
;; : DurationLiteral
(def +scoped-policy-gate-max-warm+ '400ms)

;; : (List Path)
(def +scoped-policy-gate-entry-files+
  ["t/package-build-contract-test.ss"])

;; : (-> (-> Integer) Alist)
(def (run-policy-command/silent thunk)
  (let-values (((elapsed-ns status)
                (call-with-timing
                 (lambda ()
                   (parameterize ((current-output-port (open-output-string)))
                     (thunk))))))
    (unless (and (integer? elapsed-ns) (> elapsed-ns 0))
      (error "runtime benchmark timing source returned non-positive duration"
             elapsed-ns))
    (list (cons 'status status)
          (cons 'timingSource ":clan/timestamp#call-with-timing")
          (cons 'elapsedNs elapsed-ns)
          (cons 'elapsed (duration-nanos->text elapsed-ns)))))

;; run-policy-command/silent/p95
;;   : (-> Integer (-> Integer) Alist)
;;   | doc m%
;;       Return nearest-rank p95 and retain every successful timing sample.
;;     %
(def (run-policy-command/silent/p95 attempts thunk)
  (if (<= attempts 0)
    (error "policy benchmark attempts must be positive" attempts)
    (let* ((samples
            (map (lambda (_) (run-policy-command/silent thunk))
                 (iota attempts)))
           (admission
            (benchmark-select-sample
             samples
             95
             (lambda (sample)
               (benchmark-fixture-ref sample 'elapsedNs)))))
      (cons (cons 'admissionStatistic 'p95)
            (cons (cons 'sampleStatistics
                        (benchmark-sample-statistics
                         (map (lambda (sample)
                                (benchmark-fixture-ref sample 'elapsedNs))
                              samples)))
                  admission)))))

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
(def (run-scoped-policy-warm/silent/p95 files)
  (run-policy-command/silent/p95
   20
   (lambda ()
     (run-scoped-policy-if-stale files)
     0)))

;; : TestSuite
(def benchmark-runtime-gate-test
  (test-suite "gerbil scheme runtime benchmark gate"
    (test-case "gxtest scoped policy keeps requested-file report boundary"
      (check (scoped-policy-gate-target-files) => +scoped-policy-gate-entry-files+)
      (check (length (scoped-policy-gate-target-files)) => 1))

    (test-case "gxtest scoped policy warm receipt stays in duration budget"
      (let* ((files (scoped-policy-gate-target-files))
             (cold (run-scoped-policy/silent files))
             (warm (run-scoped-policy-warm/silent/p95 files)))
        (let (statistics (benchmark-fixture-ref warm 'sampleStatistics))
          (displayln "[asp-gerbil-scheme-runtime-benchmark] name=scoped-policy-warm"
                     " p50Ns="
                     (benchmark-fixture-ref statistics 'p50Ns)
                     " p95Ns="
                     (benchmark-fixture-ref statistics 'p95Ns)
                     " maxNs="
                     (benchmark-fixture-ref statistics 'maxNs)
                     " targetWarmNs="
                     (duration-literal->nanos
                      +scoped-policy-gate-target-warm+)
                     " maxWarmNs="
                     (duration-literal->nanos +scoped-policy-gate-max-warm+)))
        (check (benchmark-fixture-ref cold 'status) => 0)
        (check (benchmark-fixture-ref warm 'status) => 0)
        (check (benchmark-fixture-ref warm 'admissionStatistic) => 'p95)
        (check (= (duration-literal->nanos +scoped-policy-gate-max-warm+)
                  (+ (duration-literal->nanos
                      +scoped-policy-gate-target-warm+)
                     (duration-literal->nanos
                      +scoped-policy-gate-regression-warm+)))
               => #t)
        (check (<= (benchmark-fixture-ref warm 'elapsedNs)
                   (duration-literal->nanos +scoped-policy-gate-max-warm+))
               => #t)))))
