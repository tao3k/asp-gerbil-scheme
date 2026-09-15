;;; -*- Gerbil -*-
;;; Agent-facing loop policy for list growth by repeated append.

(import :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/policy/model
        (only-in :std/sugar filter-map hash ormap)
        :asp-gerbil-scheme/src/types/findings)

(export list-growth-loop-performance-findings
        list-growth-loop-performance-finding)

;; (List Callee)
(def +list-growth-loop-callees+
  ["append" "append!"])

;;; Boundary:
;;; - Parser call facts own the append evidence.
;;; - Parser loop facts own loop locality.
;;; - The policy does not scan rendered source strings.
;; : (-> ProjectIndex (List TypeFinding) )
(def (list-growth-loop-performance-findings index)
  (apply append
         (map (lambda (file)
                (filter-map
                 (lambda (call)
                   (let (loop (list-growth-loop-driver file call))
                     (and loop
                          (list-growth-loop-performance-finding
                           file call loop))))
                 (source-file-calls file)))
              (project-index-files index))))

;; : (-> SourceFile CallFact (U #f LoopDriverFact) )
(def (list-growth-loop-driver file call)
  (and (member (call-fact-callee call) +list-growth-loop-callees+)
       (call-fact-caller call)
       (ormap (lambda (loop)
                (and (equal? (loop-driver-fact-caller loop)
                             (call-fact-caller call))
                     (list-growth-call-inside-loop? call loop)
                     loop))
              (source-file-loop-driver-facts file))))

;;; Locality gate:
;;; - Caller equality alone is too broad; one boundary append after a loop is
;;;   fine.
;;; - Selector offsets keep the warning loop-local and parser-owned.
;; : (-> CallFact LoopDriverFact Boolean )
(def (list-growth-call-inside-loop? call loop)
  (and (number? (call-fact-start call))
       (number? (call-fact-end call))
       (number? (loop-driver-fact-start loop))
       (number? (loop-driver-fact-end loop))
       (>= (call-fact-start call) (loop-driver-fact-start loop))
       (<= (call-fact-end call) (loop-driver-fact-end loop))))

;; : (-> LoopDriverFact String )
(def (list-growth-loop-role loop)
  (let (role (loop-driver-fact-role loop))
    (if (equal? role "manual-loop-classification")
      "manual-loop"
      role)))

;; : (-> SourceFile CallFact LoopDriverFact TypeFinding )
(def (list-growth-loop-performance-finding file call loop)
  (make-type-finding
   (policy-rule-id +agent-list-growth-loop-performance-rule+)
   (policy-rule-severity +agent-list-growth-loop-performance-rule+)
   (source-file-path file)
   (string-append
    "loop " (loop-driver-fact-name loop)
    " grows a list with " (call-fact-callee call)
    "; accumulate with cons/fold and reverse once, or build a hash/index plus ordered key boundary")
   (call-fact-selector call)
   (hash (kind "list-growth-loop-performance")
         (callee (call-fact-callee call))
         (caller (or (call-fact-caller call) "top-level"))
         (loopName (loop-driver-fact-name loop))
         (loopRole (list-growth-loop-role loop))
         (guidanceMode "performance-warning")
         (trigger "loop-local repeated append list growth")
         (allowedUse "one final append at a boundary remains valid when it is not loop-local")
         (preferredConstruction "accumulate with cons/fold and reverse once, or use hash/index state plus ordered-key reconstruction for keyed merges")
         (performanceEvidence "loop-local append copies the accumulated prefix repeatedly; Gerbil and Gambit expose append/reverse primitives, while poo-flow list merge performance fixtures use hash state and reverse-once ordered keys to avoid repeated list copying")
         (sourceEvidence "gerbil://std/misc/list.ss, gerbil://gambit/tests/unit-tests/04-list/append_reverse.scm, poo-flow/src/module-system/extension-support/merge.ss")
         (repairStrategies ["cons-reverse-once"
                            "fold-accumulator"
                            "hash-index-with-ordered-keys"
                            "single-boundary-append"])
         (next "move append out of the loop or replace loop-local list growth with an accumulator boundary"))))
