;;; -*- Gerbil -*-
;;; Boundary:
;;; - test owner records policy expectations.
;;; - Keep typed contracts and fixture intent explicit.
(import :asp-gerbil-scheme/src/language/facade
        :asp-gerbil-scheme/src/snapshot/facade
        :std/test)

(export check-runtime-source-snapshot-fields
        check-runtime-source-snapshot-fixtures)
;; : (-> String String )
(def (runtime-source-fact-by-id id)
  (or (find (lambda (fact)
              (equal? (hash-get fact 'id) id))
            (runtime-source-facts))
      (error "runtime source fact not found" id)))
;; Snapshot
(def (check-runtime-source-snapshot-fields)
  (let (fact (runtime-source-fact-by-id "gerbil-runtime-writeenv-source"))
    (check (runtime-source-search-snapshot
            "writeenv printer hook"
            [fact]
            (hash-get fact 'next))
           => (snapshot-load "t/snapshots/runtime-source-writeenv-acquisition.ss"))))
;; Snapshot
(def (check-runtime-source-snapshot-fixtures)
  (let ((macro-fact (runtime-source-fact-by-id "gerbil-runtime-source"))
        (writeenv-fact (runtime-source-fact-by-id "gerbil-runtime-writeenv-source")))
    (check (runtime-source-search-snapshot
            "macro"
            [macro-fact]
            (hash-get macro-fact 'next))
           => (snapshot-load "t/snapshots/runtime-source-macro-acquisition.ss"))
    (check (runtime-source-search-snapshot
            "writeenv printer hook"
            [writeenv-fact]
            (hash-get writeenv-fact 'next))
           => (snapshot-load "t/snapshots/runtime-source-writeenv-acquisition.ss"))))
