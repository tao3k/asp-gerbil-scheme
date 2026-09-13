;;; -*- Gerbil -*-
;;; Agent-facing loop policy for random access over lists.

(import :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/policy/model
        (only-in :std/sugar filter-map hash ormap)
        :asp-gerbil-scheme/src/types/findings)

(export list-random-access-loop-performance-findings
        list-random-access-loop-performance-finding)

;; (List Callee)
(def +list-random-access-loop-callees+
  ["list-ref" "list-tail"])

;;; Boundary:
;;; - Parser call facts own list random-access evidence.
;;; - Parser loop facts own loop locality.
;;; - This rule complements R039 list growth; it does not scan source strings.
;; : (-> ProjectIndex (List TypeFinding) )
(def (list-random-access-loop-performance-findings index)
  (apply append
         (map (lambda (file)
                (filter-map
                 (lambda (call)
                   (let (loop (list-random-access-loop-driver file call))
                     (and loop
                          (list-random-access-loop-performance-finding
                           file call loop))))
                 (source-file-calls file)))
              (project-index-files index))))

;; : (-> SourceFile CallFact (U #f LoopDriverFact) )
(def (list-random-access-loop-driver file call)
  (and (member (call-fact-callee call) +list-random-access-loop-callees+)
       (call-fact-caller call)
       (ormap (lambda (loop)
                (and (equal? (loop-driver-fact-caller loop)
                             (call-fact-caller call))
                     (list-random-access-call-inside-loop? call loop)
                     loop))
              (source-file-loop-driver-facts file))))

;; : (-> CallFact LoopDriverFact Boolean )
(def (list-random-access-call-inside-loop? call loop)
  (and (number? (call-fact-start call))
       (number? (call-fact-end call))
       (number? (loop-driver-fact-start loop))
       (number? (loop-driver-fact-end loop))
       (>= (call-fact-start call) (loop-driver-fact-start loop))
       (<= (call-fact-end call) (loop-driver-fact-end loop))))

;; : (-> LoopDriverFact String )
(def (list-random-access-loop-role loop)
  (let (role (loop-driver-fact-role loop))
    (if (equal? role "manual-loop-classification")
      "manual-loop"
      role)))

;; : (-> SourceFile CallFact LoopDriverFact TypeFinding )
(def (list-random-access-loop-performance-finding file call loop)
  (make-type-finding
   (policy-rule-id +agent-list-random-access-loop-performance-rule+)
   (policy-rule-severity +agent-list-random-access-loop-performance-rule+)
   (source-file-path file)
   (string-append
    "loop " (loop-driver-fact-name loop)
    " performs list random access with " (call-fact-callee call)
    "; convert once to vector/evector before indexed traversal")
   (call-fact-selector call)
   (hash (kind "list-random-access-loop-performance")
         (callee (call-fact-callee call))
         (caller (or (call-fact-caller call) "top-level"))
         (loopName (loop-driver-fact-name loop))
         (loopRole (list-random-access-loop-role loop))
         (guidanceMode "performance-warning")
         (trigger "loop-local list-ref/list-tail random access")
         (allowedUse "single boundary list-ref outside an indexed traversal remains valid")
         (preferredConstruction "convert immutable input with list->vector once, or use std/misc/evector for growable indexed data")
         (performanceEvidence "list-ref and list-tail traverse from the list head; Gerbil std/misc/evector provides growable vectors with fill pointers for indexed hot paths")
         (sourceEvidence "gerbil://std/misc/evector.ss, gerbil://std/misc/vector.ss, poo-flow/t/flow-strand-performance-test.ss#large-registry-performance-gate")
         (repairStrategies ["list-to-vector-boundary"
                            "evector-growable-indexed-buffer"
                            "single-pass-fold-with-index"
                            "deque-for-front-back-queue"])
         (next "move list random access out of the loop or materialize an indexed collection boundary first"))))
