;;; -*- Gerbil -*-
;;; Boundary:
;;; - Class precedence is represented as a local descriptor.
;;; - Tail merge and duplicate filtering are helper-owned, following the shape
;;;   of Gerbil runtime/c3.ss instead of a broad superclass walker.
(package: sample/linearization)
(export resolve-precedence)

;; precedence-node
;;   : (-> Class DirectSupers PrecedenceNode)
;;   | type Class = Symbol
;;   | type DirectSupers = (List Class)
;;   | doc m%
;;       `precedence-node` names the local MOP descriptor used by the
;;       linearization boundary.
;;     %
(defclass precedence-node (klass supers)
  final: #t)

;; make-precedence-node
;;   : (-> Class DirectSupers PrecedenceNode)
;;   | type Class = Symbol
;;   | type DirectSupers = List
;;   | doc m%
;;       `make-precedence-node klass supers` normalizes the input shape once
;;       before C3-style merge helpers run.
;;     %
(def (make-precedence-node klass supers)
  (precedence-node klass: klass supers: supers))

;; precedence-tail
;;   : (-> PrecedenceNode PrecedenceTail)
;;   | type PrecedenceTail = (List Class)
;;   | doc m%
;;       `precedence-tail node` owns superclass tail extraction through a typed
;;       descriptor boundary.
;;     %
(def (precedence-tail node)
  (using (node :- precedence-node)
    node.supers))

;; merge-precedence-tail
;;   : (-> PrecedenceTail PrecedenceList PrecedenceList)
;;   | type PrecedenceList = (List Class)
;;   | doc m%
;;       `merge-precedence-tail tail order` keeps duplicate filtering local to
;;       the merge helper.
;;     %
(def (merge-precedence-tail tail order)
  (foldl (lambda (klass order)
           (if (member klass order)
             order
             (cons klass order)))
         order
         tail))

;; resolve-precedence
;;   : (-> Class DirectSupers PrecedenceList)
;;   | type Class = Symbol
;;   | type DirectSupers = (List Class)
;;   | doc m%
;;       `resolve-precedence klass direct-supers` is a small orchestration
;;       boundary around the descriptor and tail merge helpers.
;;
;;       # Examples
;;
;;       ```scheme
;;       (resolve-precedence 'button ['widget 'object])
;;       ;; => '(button widget object)
;;       ```
;;     %
(def (resolve-precedence klass direct-supers)
  (let* ((node (make-precedence-node klass direct-supers))
         (order (merge-precedence-tail (precedence-tail node) [klass])))
    (reverse order)))
