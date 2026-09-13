;;; -*- Gerbil -*-
;;; Public module wrapper for the source-bootstrapped memory anomaly guard.

(import :gerbil/gambit
        (only-in :clan/poo/object .has? .o .ref object?)
        (only-in :std/misc/process run-process)
        (only-in :std/srfi/13 string-suffix? string-tokenize)
        (only-in :std/text/json json-object->string write-json-sort-keys?)
        (only-in ../build-api/core-capacity native-build-core-count))

;;; Keep this module owner fresh when the shared classifier/control-loop body
;;; changes; std/make does not model include-file timestamps independently.
(include "memory-anomaly-guard-body.inc")

(export framework-memory-anomaly-policy
        framework-memory-anomaly-policy?
        framework-memory-anomaly-sample
        framework-memory-anomaly-sample?
        framework-memory-anomaly-window
        framework-memory-anomaly-growth-bytes
        framework-memory-anomaly-growth-rate-bytes-per-second
        framework-memory-anomaly-transition
        framework-memory-guard-process-table
        framework-memory-guard-runtime-heap-bytes
        framework-memory-guard-load-average
        framework-memory-guard-active-compiler-jobs
        framework-memory-guard-process-tree-cpu-percent
        framework-memory-anomaly-receipt
        framework-build-start-line
        call-with-framework-memory-anomaly-guard
        call-with-framework-native-build-memory-anomaly-guard)

;; call-with-framework-native-build-memory-anomaly-guard
;;   : (forall (a) (-> String (-> a) a))
;;   : (-> BuildLabel BuildThunk BuildResult)
;;   | doc m%
;;       Downstream build scripts use this composition instead of duplicating
;;       the caller-override or host-capacity selection rule.  PackageSpec still
;;       owns capacity mutation immediately before std/make constructs settings;
;;       the guard observes the same value without limiting native parallelism.
;;     %
(def (call-with-framework-native-build-memory-anomaly-guard
      label thunk (trace? #f) (start-phase 'std-make-start))
  (call-with-framework-memory-anomaly-guard
   label
   (native-build-core-count
    (getenv "GERBIL_BUILD_CORES" #f)
    (##cpu-count))
   thunk
   trace?
   start-phase))
