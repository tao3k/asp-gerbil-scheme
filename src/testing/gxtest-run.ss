;;; -*- Gerbil -*-
;;; Gxtest run-mode orchestration.
;;;
;;; Boundary:
;;; - This module owns runtime mode selection after policy/build receipts are
;;;   current.
;;; - Discovery owns file classification, build owns stale compilation, and
;;;   execution owns subprocess/in-process mechanics.
;;; - Keeping this layer separate prevents the public runner facade from
;;;   mixing test target parsing with performance-sensitive scheduling.

(import (only-in :std/srfi/1 partition any)
        (only-in "../support/time" monotonic-micros duration-micros)
        (only-in "./gxtest-build"
                 compile-selected-gxtest-if-stale)
        (only-in "./gxtest-discovery"
                 compiled-in-process-gxtest-file?
                 gxtest-files-local-suite?
                 parallel-gxtest-files
                 serial-gxtest-files)
        (only-in "./gxtest-execution"
                 run-gxtest-parallel-phase
                 run-gxtest-serial-phase
                 display-gxtest-failures
                 display-gxtest-timing-summary
                 display-gxtest-result
                 first-failure-status
                 gxtest-runner-mode-label
                 gxtest-native-parallelism)
        (only-in "./gxtest-receipts"
                 selected-gxtest-build-current?)
        (only-in "./memory-profile"
                 gxtest-file-memory-exception?)
        :gerbil/gambit)

(export run-gxtest-files
        gxtest-suite-process-isolated?)

;; A multi-file suite must cross a process boundary between files so loaded
;; modules and test state cannot accumulate for the lifetime of the full run.
(def (gxtest-suite-process-isolated? files)
  (> (length files) 1))

;; split-in-process-gxtest-files
;;   : (-> (List Path) (Values (List Path) (List Path)))
;;   | doc m%
;;       Split a selected in-process batch once into compiled-safe files and
;;       source-only files.  `compiled-in-process-gxtest-file?` reads syntax and
;;       import-closure facts, so runner planning must not re-run it for mode
;;       labels, scheduling, and execution.
;;     %
(def (split-in-process-gxtest-files files)
  (partition compiled-in-process-gxtest-file? files))

;; : (-> (List Path) (List GxTestResult))
(def (run-source-safe-in-process-gxtest-files files)
  (if (null? files)
    []
    (run-gxtest-parallel-phase files files #t #f)))

;; : (-> (List Path) (List GxTestResult))
(def (run-compiled-in-process-gxtest-files files)
  (if (null? files)
    []
    (let* ((selected-status
            (compile-selected-gxtest-if-stale files))
           (compiled-in-process?
            (selected-gxtest-build-current? selected-status)))
      (run-gxtest-parallel-phase files
                                 files
                                 #t
                                 compiled-in-process?))))

;; : (-> (List Path) (List GxTestResult))
(def (run-source-only-in-process-gxtest-files files)
  (if (null? files)
    []
    (run-gxtest-parallel-phase files files #t #f)))

;; : (-> (List Path) (List GxTestResult))
(def (run-split-source-in-process-gxtest-files source-safe-files
                                               source-only-files)
  (append (run-source-safe-in-process-gxtest-files
           source-safe-files)
          (run-source-only-in-process-gxtest-files
           source-only-files)))

;; : (-> (List Path) (List Path) (List Path) (List GxTestResult))
(def (run-in-process-gxtest-files files
                                  source-safe-files
                                  source-only-files)
  (if (pair? source-only-files)
    (run-split-source-in-process-gxtest-files source-safe-files
                                               source-only-files)
    (run-compiled-in-process-gxtest-files files)))

;; : (-> Boolean Boolean Boolean String)
(def (gxtest-runner-effective-mode source-in-process?
                                   compiled-in-process?
                                   split-source-in-process?)
  (if split-source-in-process?
    "split-source-in-process"
    (gxtest-runner-mode-label source-in-process? compiled-in-process?)))

;; run-gxtest-files
;;   : (-> (List Path) Void)
;;   | doc m%
;;       `run-gxtest-files` owns the run-mode boundary after policy and build
;;       receipts are current.  It keeps local-suite batches in-process for the
;;       warm path, falls back to subprocess execution for isolated or
;;       timing-sensitive files, and emits machine-parseable timing receipts so
;;       performance regressions stay visible to callers.
;;     %
(def (run-gxtest-files files)
  (let* ((parallel-files (parallel-gxtest-files files))
         (serial-files (serial-gxtest-files files))
         (source-in-process?
          (and (not (gxtest-suite-process-isolated? files))
               (gxtest-files-local-suite? files)
               (not (any gxtest-file-memory-exception? files)))))
    (let-values (((source-safe-files source-only-files)
                  (if source-in-process?
                    (split-in-process-gxtest-files files)
                    (values [] []))))
      (let* ((source-only-in-process? (pair? source-only-files))
             (compiled-in-process?
              (and source-in-process?
                   (not source-only-in-process?)))
             (split-source-in-process?
              (and source-in-process?
                   source-only-in-process?
                   (pair? source-safe-files)))
             (parallel-start-micros (monotonic-micros))
             (parallel-results
              (if source-in-process?
                (run-in-process-gxtest-files files
                                             source-safe-files
                                             source-only-files)
                (run-gxtest-parallel-phase files
                                           parallel-files
                                           #f
                                           #f)))
             (parallel-wall-micros
              (duration-micros parallel-start-micros (monotonic-micros)))
             (serial-start-micros (monotonic-micros))
             (serial-results
              (run-gxtest-serial-phase serial-files source-in-process?))
             (serial-wall-micros
              (duration-micros serial-start-micros (monotonic-micros)))
             (results (append parallel-results serial-results))
             (status (first-failure-status results)))
        (display (string-append "[asp-gerbil-scheme-test-runner] files="
                                (number->string (length files))
                                " process-isolation=per-file"
                                " native-parallelism="
                                (number->string
                                 (gxtest-native-parallelism
                                  (length parallel-files)))
                                " serial="
                                (number->string (length serial-files))
                                " mode="
                                (gxtest-runner-effective-mode
                                 source-in-process?
                                 compiled-in-process?
                                 split-source-in-process?)
                                "\n"))
        (force-output)
        (display-gxtest-timing-summary parallel-results
                                       serial-results
                                       parallel-wall-micros
                                       serial-wall-micros)
        (display-gxtest-failures results)
        (for-each display-gxtest-result results)
        (if (zero? status)
          (begin
            (display "OK\n")
            (force-output))
          (exit status))))))
