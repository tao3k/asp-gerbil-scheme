;;; -*- Gerbil -*-
;;; Agent-authored superclass walker with ad hoc precedence logic.
(package: sample/linearization)
(export resolve-precedence)

;; : (-> Class DirectSupers C3PrecedenceList)
(def (resolve-precedence klass direct-supers)
  (let loop ((rest direct-supers) (order [klass]))
    (match rest
      ([]
       (reverse order))
      ([super . rest]
       (let (parent-order
             (if (and (pair? super)
                      (pair? (cdr super)))
               (cdr super)
               []))
         (let (next-order
               (foldl (lambda (parent order)
                        (if (member parent order)
                          order
                          (cons parent order)))
                      (if (member super order)
                        order
                        (cons super order))
                      parent-order))
           (loop rest next-order)))))))
