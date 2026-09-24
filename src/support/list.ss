;;; -*- Gerbil -*-
;;; Preserve first-occurrence order through V19's hash-based list primitive.

(import (only-in :std/list/list delete-duplicates/hash)
        (only-in :std/list/list-builder with-list-builder))
(export unique append-map)

;; unique
;;   : (forall (a) (-> (List a) (List a)))
;;   : (-> (List ModuleId) (List ModuleId))
;;   | doc m%
;;       Preserve the first occurrence of each value while delegating the
;;       membership index to V19's native hash-backed list operation.
;;
;;       # Examples
;;       ```scheme
;;       (unique '(a b a c))
;;       ;; => (a b c)
;;       ```
;;     %
(def (unique values)
  (delete-duplicates/hash values from-end?: #t))

;; append-map
;;   : (forall (a b) (-> (-> a (List b)) (List a) (List b)))
;;   : (-> (-> Owner (List Fact)) (List Owner) (List Fact))
;;   V19's std/list/list append-map reverses each mapped sublist. Delegate
;;   ordered accumulation to V19's native list builder until upstream fixes it.
(def (append-map proc values)
  (with-list-builder (push)
    (for-each
     (lambda (value)
       (for-each push (proc value)))
     values)))
