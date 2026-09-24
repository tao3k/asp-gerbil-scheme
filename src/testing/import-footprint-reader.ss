;;; -*- Gerbil -*-
;;; Reader-only direct import projection for the testing footprint preflight.

(import :gerbil/runtime/gambit
        (only-in :std/list/list filter-map foldl))

(export testing-import-footprint-datum-owners
        testing-import-footprint-file-owners)

;; : (-> ImportSpec (Maybe ImportOwner))
(def (testing-import-spec-owner spec)
  (cond
   ((or (symbol? spec) (string? spec)) spec)
   ((and (pair? spec)
         (memq (car spec)
               '(only-in except-in rename-in prefix-in
                 for-syntax for-template for-label))
         (pair? (cdr spec)))
    (testing-import-spec-owner (cadr spec)))
   (else #f)))

;;; Quoted data is inert; import wrappers remain traversable.
;; : (-> Datum (List ImportOwner))
(def (testing-import-footprint-datum-owners datum)
  (cond
   ((not (pair? datum)) [])
   ((memq (car datum) '(quote quasiquote syntax quasisyntax)) [])
   ((eq? (car datum) 'import)
    (filter-map testing-import-spec-owner (cdr datum)))
   (else
    (append (testing-import-footprint-datum-owners (car datum))
            (testing-import-footprint-datum-owners (cdr datum))))))

;; : (-> InputPort (List ImportOwner))
(def (testing-import-footprint-port-owners port)
  (let loop ((owners-rev []))
    (let (datum (read port))
      (if (eof-object? datum)
        (reverse owners-rev)
        (loop
         (foldl cons owners-rev
                (testing-import-footprint-datum-owners datum)))))))

;; testing-import-footprint-file-owners
;;   : (forall (p o) (-> p (List o)))
;;   : (-> Path (List ImportOwner))
;;   | rationale keep reader IO separate from import-owner projection
;;   | doc m%
;;       Read direct import owners without loading or expanding the module.
;;
;;       # Examples
;;
;;       ```scheme
;;       (testing-import-footprint-file-owners "t/example-test.ss")
;;       ;; => (:std/test :example/library)
;;       ```
;;
;;       Result: import owners in source order.
;;     %
(def (testing-import-footprint-file-owners path)
  (call-with-input-file path testing-import-footprint-port-owners))
