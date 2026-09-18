;;; -*- Gerbil -*-

(import (only-in :std/test test-suite test-case check)
        "./state")

(export prepared-source-witness-test)

;;; This side effect occurs while gxtest prepares the module, before it runs
;;; any exported TestSuite.
(mark-prepared-source-witness-ready!)

(def prepared-source-witness-test
  (test-suite "prepared source witness"
    (test-case "the witness module was prepared"
      (check prepared-source-witness-ready? => #t))))
