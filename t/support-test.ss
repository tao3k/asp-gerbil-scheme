;;; -*- Gerbil -*-
;;; Boundary:
;;; - Time helpers expose one unit-safe conversion surface for benchmark receipts.
;;; - Negative or absent durations remain explicit missing evidence, never measured values.
(import (only-in :std/test test-suite test-case check)
        :asp-gerbil-scheme/src/support/time)

(export support-test)
;; SupportTest
(def support-test
  (test-suite "gerbil scheme harness support helpers"
    (test-case "time helpers normalize measured duration state"
      (check (duration-ms 10 25) => 15)
      (check (average-duration-ms 15 3) => 5)
      (check (duration-state 0) => "measured")
      (check (duration-state 12) => "measured")
      (check (duration-state -1) => "missing")
      (check (duration-state #f) => "missing"))
    (test-case "duration helpers preserve sub-millisecond literals"
      (check (duration-nanos->literal 0) => '0ns)
      (check (duration-nanos->literal 800) => '800ns)
      (check (duration-nanos->literal 75000) => '75us)
      (check (duration-nanos->literal 1200000) => '1.2ms)
      (check (duration-nanos->literal 1000000000) => '1s)
      (check (duration-nanos->text -75000) => "-75us")
      (check (duration-literal->nanos '800ns) => 800)
      (check (duration-literal->nanos '75us) => 75000)
      (check (duration-literal->nanos '1.2ms) => 1200000))))
