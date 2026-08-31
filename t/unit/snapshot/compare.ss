;;; -*- Gerbil -*-
;;; Boundary:
;;; - test owner records policy expectations.
;;; - Keep typed contracts and fixture intent explicit.
(import :asp-gerbil-scheme/src/language/facade
        :asp-gerbil-scheme/src/snapshot/facade
        :std/test)

(export check-compare-snapshot-fields
        check-compare-snapshot-fixtures)
;; : (-> String String )
(def (compare-fact-by-id id)
  (or (find (lambda (fact)
              (equal? (hash-get fact 'id) id))
            (compare-facts))
      (error "compare fact not found" id)))
;; Snapshot
(def (check-compare-snapshot-fields)
  (let (fact (compare-fact-by-id "env-active-documented"))
    (check (compare-search-snapshot
            "env active documented"
            [fact]
            (hash-get fact 'next))
           => (snapshot-load "t/snapshots/compare-env-active-documented.ss"))))
;; Snapshot
(def (check-compare-snapshot-fixtures)
  (let ((fact (compare-fact-by-id "env-active-documented"))
        (compile-fact (compare-fact-by-id "compile-target-runtime-source")))
    (check (compare-search-snapshot
            "env active documented"
            [fact]
            (hash-get fact 'next))
           => (snapshot-load "t/snapshots/compare-env-active-documented.ss"))
    (check (compare-search-snapshot
            "compile v0.18 v0.19 nightly"
            [compile-fact]
            (hash-get compile-fact 'next))
           => (snapshot-load "t/snapshots/compare-compile-target-runtime-source.ss"))
    (check (map (lambda (fact) (hash-get fact 'id))
                (matching-compare-facts ["compile-target" "runtime-source"]))
           => ["compile-target-runtime-source"])))
