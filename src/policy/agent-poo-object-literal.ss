;;; -*- Gerbil -*-
;;; POO object literal shape helpers shared by policy modules.

(import :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/policy/agent-poo-callees)

(export poo-large-data-object-literal-call?
        poo-object-literal-slot-spec-count>=?
        poo-object-literal-slot-spec-count)

;; : (-> CallFact Boolean )
(def (poo-large-data-object-literal-call? call)
  (and (member (call-fact-callee call) +poo-data-object-literal-callees+)
       (poo-object-literal-slot-spec-count>=?
        call
        +poo-data-object-literal-min-slot-specs+)))

;; : (-> CallFact Integer Boolean )
(def (poo-object-literal-slot-spec-count>=? call limit)
  (poo-object-literal-slot-spec-count/args>=? (call-fact-arguments call)
                                              limit))

;; : (-> CallFact Integer )
(def (poo-object-literal-slot-spec-count call)
  (poo-object-literal-slot-spec-count/args (call-fact-arguments call)))

;; : (-> (List String) Integer )
(def (poo-object-literal-slot-spec-count/args args)
  (cond
   ((null? args) 0)
   ((poo-keyword-slot-argument? (car args))
    (+ 1
       (poo-object-literal-slot-spec-count/args
        (if (pair? (cdr args))
          (cddr args)
          (cdr args)))))
   (else
    (+ 1 (poo-object-literal-slot-spec-count/args (cdr args))))))

;; : (-> (List String) Integer Boolean )
(def (poo-object-literal-slot-spec-count/args>=? args limit)
  (cond
   ((<= limit 0) #t)
   ((null? args) #f)
   ((poo-keyword-slot-argument? (car args))
    (poo-object-literal-slot-spec-count/args>=?
     (poo-object-literal-slot-spec-rest args)
     (- limit 1)))
   (else
    (poo-object-literal-slot-spec-count/args>=? (cdr args)
                                                (- limit 1)))))

;; : (-> (List String) (List String))
(def (poo-object-literal-slot-spec-rest args)
  (if (pair? (cdr args))
    (cddr args)
    (cdr args)))

;; : (-> String Boolean )
(def (poo-keyword-slot-argument? arg)
  (and (> (string-length arg) 0)
       (char=? (string-ref arg (- (string-length arg) 1)) #\:)))
