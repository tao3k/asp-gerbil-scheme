;;; -*- Gerbil -*-
;;; Shared parser-fact locality helpers for POO loop policies.

(import :asp-gerbil-scheme/src/parser/facade
        (only-in :std/sugar ormap)
        :gerbil/gambit)

(export poo-call-loop-driver
        poo-call-inside-loop-driver?
        poo-loop-driver-agent-role)

;;; Loop lookup boundary:
;;; - Match a POO call to the parser-owned loop driver for the same caller.
;;; - The first range-valid fact is the executable locality witness.
;; : (-> SourceFile CallFact (Maybe LoopDriverFact))
(def (poo-call-loop-driver file call)
  (and (call-fact-caller call)
       (ormap (lambda (loop)
                (and (equal? (loop-driver-fact-caller loop)
                             (call-fact-caller call))
                     (poo-call-inside-loop-driver? call loop)
                     loop))
              (source-file-loop-driver-facts file))))

;;; Loop locality boundary:
;;; - Caller identity alone cannot prove that a POO operation occurs inside a
;;;   loop, because a function may hoist the operation around that loop.
;;; - Both parser-owned source ranges must contain the call completely.
;; : (-> CallFact LoopDriverFact Boolean)
(def (poo-call-inside-loop-driver? call loop)
  (and (number? (call-fact-start call))
       (number? (call-fact-end call))
       (number? (loop-driver-fact-start loop))
       (number? (loop-driver-fact-end loop))
       (>= (call-fact-start call) (loop-driver-fact-start loop))
       (<= (call-fact-end call) (loop-driver-fact-end loop))))

;; : (-> LoopDriverFact String)
(def (poo-loop-driver-agent-role loop)
  (let (role (loop-driver-fact-role loop))
    (if (equal? role "manual-loop-classification")
      "manual-loop"
      role)))
