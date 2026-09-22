;;; -*- Gerbil -*-
;;; POO guidance corpus snapshot test.
;;; This test runs a source-load check in a fresh gxi process so local scenario
;;; edits are not hidden by an installed package copy of t/unit/snapshot/policy.ss.

(import :gerbil/runtime/gambit
        :std/test)

(export poo-guidance-corpus-test)

;; : (-> Snapshot)
(def (poo-guidance-corpus-actual)
  (add-load-path! "src")
  (add-load-path! "t")
  (load "t/unit/snapshot/policy.ss")
  (eval '(poo-guidance-corpus-policy-snapshot)))

(def poo-guidance-corpus-test
  (test-suite "gerbil scheme harness POO guidance corpus"
    (test-case "POO guidance corpus matches local scenario facts"
      (check (poo-guidance-corpus-actual)
             => (call-with-input-file
                  "t/snapshots/policy-poo-guidance-corpus.ss"
                  read)))))
