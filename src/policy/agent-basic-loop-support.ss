;;; -*- Gerbil -*-
;;; Parser-backed exclusions for structural and materializing named lets.

(import :gerbil/runtime/gambit
        :asp-gerbil-scheme/src/parser/facade
        (only-in :std/string/misc string-prefix?))

(export manual-loop-projection-recursion?
        manual-loop-nested-driver?
        manual-loop-materializes-output?)

;;; Two projections such as (cdr left)/(cdr right) express structural
;;; recursion, not a carried accumulator. An idiom rewrite has no proven gain.
;; : (-> SourceFile ControlFlowFact Boolean)
(def (manual-loop-projection-recursion? file fact)
  (let (calls
        (filter (cut manual-loop-recursive-call? fact <>)
                (source-file-calls file)))
    (and (pair? calls)
         (andmap (lambda (call)
                   (andmap (lambda (arg)
                             (or (string-prefix? "(car " arg)
                                 (string-prefix? "(cdr " arg)))
                           (call-fact-arguments call)))
                 calls))))

;; : (-> ControlFlowFact CallFact Boolean)
(def (manual-loop-recursive-call? fact call)
  (and (equal? (call-fact-caller call)
               (control-flow-fact-caller fact))
       (equal? (call-fact-callee call)
               (control-flow-fact-name fact))
       (>= (call-fact-start call)
           (control-flow-fact-start fact))
       (<= (call-fact-end call)
           (control-flow-fact-end fact))))

;;; Nested traversal and per-row output construction have a control or
;;; materialization purpose. A fold rewrite requires separate cost evidence.
;; : (-> SourceFile ControlFlowFact Boolean)
(def (manual-loop-nested-driver? file fact)
  (ormap (cut manual-loop-contained-driver? fact <>)
         (source-file-loop-driver-facts file)))

;; : (-> ControlFlowFact LoopDriverFact Boolean)
(def (manual-loop-contained-driver? fact driver)
  (and (equal? (loop-driver-fact-caller driver)
               (control-flow-fact-caller fact))
       (manual-loop-distinct-driver? fact driver)
       (>= (loop-driver-fact-start driver)
           (control-flow-fact-start fact))
       (<= (loop-driver-fact-end driver)
           (control-flow-fact-end fact))))

;; : (-> ControlFlowFact LoopDriverFact Boolean)
(def (manual-loop-distinct-driver? fact driver)
  (not (equal? (loop-driver-fact-name driver)
               (control-flow-fact-name fact))))

;; : (-> SourceFile ControlFlowFact Boolean)
(def (manual-loop-materializes-output? file fact)
  (ormap
   (lambda (call)
     (and (equal? (call-fact-caller call)
                  (control-flow-fact-caller fact))
          (equal? (call-fact-callee call) ".o")
          (>= (call-fact-start call)
              (control-flow-fact-start fact))
          (<= (call-fact-end call)
              (control-flow-fact-end fact))))
   (source-file-calls file)))
