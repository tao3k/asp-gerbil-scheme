;;; -*- Gerbil -*-
;;; Pure TypeSpec union normalization primitives shared by validation.

(import :gerbil/gambit
        (only-in :asp-gerbil-scheme/src/types/model
                 type=?
                 type-kind
                 type-union-members))

(export flatten-union-members
        unique-types
        validation-name)

;; flatten-union-members
;;   : (-> UnionMembers UnionMembers)
;;   | type UnionMembers = (List TypeSpec)
;;   | doc m%
;;       Removes nested union shells while preserving member order.
;;     %
(def (flatten-union-members members)
  (cond
   ((null? members) [])
   ((eq? (type-kind (car members)) 'union)
    (append (flatten-union-members (type-union-members (car members)))
            (flatten-union-members (cdr members))))
   (else
    (cons (car members) (flatten-union-members (cdr members))))))

;; unique-types
;;   : (-> UnionMembers UnionMembers UnionMembers)
;;   | type UnionMembers = (List TypeSpec)
;;   | doc m%
;;       Keeps the first structural occurrence of each TypeSpec.
;;     %
(def (unique-types members out)
  (cond
   ((null? members) (reverse out))
   ((contains-type? (car members) out)
    (unique-types (cdr members) out))
   (else
    (unique-types (cdr members) (cons (car members) out)))))

;; : (-> TypeSpec UnionMembers Boolean)
(def (contains-type? target members)
  (cond
   ((null? members) #f)
   ((type=? target (car members)) #t)
   (else (contains-type? target (cdr members)))))

;; : (-> TypeName TypeName)
(def (validation-name name)
  (cond
   ((symbol? name) (symbol->string name))
   ((string? name) name)
   (else "unknown")))
