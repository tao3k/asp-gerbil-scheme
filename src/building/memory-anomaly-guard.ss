;;; -*- Gerbil -*-
;;; Public module wrapper for the source-bootstrapped memory anomaly guard.

(import :gerbil/gambit
        :clan/poo/object
        (only-in :std/misc/process run-process)
        (only-in :std/srfi/13 string-suffix? string-tokenize)
        (only-in :std/text/json json-object->string write-json-sort-keys?))

(include "memory-anomaly-guard-body.inc")

(export framework-memory-anomaly-policy
        framework-memory-anomaly-policy?
        framework-memory-anomaly-sample
        framework-memory-anomaly-sample?
        framework-memory-anomaly-window
        framework-memory-anomaly-growth-bytes
        framework-memory-anomaly-growth-rate-bytes-per-second
        framework-memory-anomaly-transition
        framework-memory-guard-active-compiler-jobs
        framework-memory-guard-process-tree-cpu-percent
        call-with-framework-memory-anomaly-guard)
