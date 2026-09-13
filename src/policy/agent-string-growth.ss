;;; -*- Gerbil -*-
;;; Agent-facing loop policy for string growth by repeated append.

(import :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/policy/model
        (only-in :std/sugar filter-map hash ormap)
        :asp-gerbil-scheme/src/types/findings)

(export string-growth-loop-performance-findings
        string-growth-loop-performance-finding)

;; (List Callee)
(def +string-growth-loop-callees+
  ["string-append"])

;;; Boundary:
;;; - Parser call facts own the string-append evidence.
;;; - Parser loop facts own loop locality.
;;; - This rule targets generated O(n^2) string builders without scanning source text.
;; : (-> ProjectIndex (List TypeFinding) )
(def (string-growth-loop-performance-findings index)
  (apply append
         (map (lambda (file)
                (filter-map
                 (lambda (call)
                   (let (loop (string-growth-loop-driver file call))
                     (and loop
                          (string-growth-loop-performance-finding
                           file call loop))))
                 (source-file-calls file)))
              (project-index-files index))))

;; : (-> SourceFile CallFact (U #f LoopDriverFact) )
(def (string-growth-loop-driver file call)
  (and (member (call-fact-callee call) +string-growth-loop-callees+)
       (call-fact-caller call)
       (ormap (lambda (loop)
                (and (equal? (loop-driver-fact-caller loop)
                             (call-fact-caller call))
                     (string-growth-call-inside-loop? call loop)
                     (string-growth-call-feeds-loop? file call loop)
                     loop))
              (source-file-loop-driver-facts file))))

;;; A loop-local append is growth only when its result is carried into the
;;; recursive driver call.  Per-item identifiers and labels may legitimately
;;; use string-append inside a loop without accumulating the previous string.
;; : (-> SourceFile CallFact LoopDriverFact Boolean )
(def (string-growth-call-feeds-loop? file call loop)
  (ormap
   (lambda (candidate)
     (and (equal? (call-fact-callee candidate)
                  (loop-driver-fact-name loop))
          (equal? (call-fact-caller candidate)
                  (call-fact-caller call))
          (number? (call-fact-start candidate))
          (number? (call-fact-end candidate))
          (>= (call-fact-start call) (call-fact-start candidate))
          (<= (call-fact-end call) (call-fact-end candidate))))
   (source-file-calls file)))

;; : (-> CallFact LoopDriverFact Boolean )
(def (string-growth-call-inside-loop? call loop)
  (and (number? (call-fact-start call))
       (number? (call-fact-end call))
       (number? (loop-driver-fact-start loop))
       (number? (loop-driver-fact-end loop))
       (>= (call-fact-start call) (loop-driver-fact-start loop))
       (<= (call-fact-end call) (loop-driver-fact-end loop))))

;; : (-> LoopDriverFact String )
(def (string-growth-loop-role loop)
  (let (role (loop-driver-fact-role loop))
    (if (equal? role "manual-loop-classification")
      "manual-loop"
      role)))

;; : (-> SourceFile CallFact LoopDriverFact TypeFinding )
(def (string-growth-loop-performance-finding file call loop)
  (make-type-finding
   (policy-rule-id +agent-string-growth-loop-performance-rule+)
   (policy-rule-severity +agent-string-growth-loop-performance-rule+)
   (source-file-path file)
   (string-append
    "loop " (loop-driver-fact-name loop)
    " grows a string with " (call-fact-callee call)
    "; use an output port, string-join, or a bytes/u8vector buffer boundary")
   (call-fact-selector call)
   (hash (kind "string-growth-loop-performance")
         (callee (call-fact-callee call))
         (caller (or (call-fact-caller call) "top-level"))
         (loopName (loop-driver-fact-name loop))
         (loopRole (string-growth-loop-role loop))
         (guidanceMode "performance-warning")
         (trigger "loop-local repeated string-append growth")
         (allowedUse "one final string-append at a boundary remains valid when it is not loop-local")
         (preferredConstruction "stream fragments to an output string port, use string-join for known fragment lists, or build bytes with u8vector/buffer state before one decode boundary")
         (performanceEvidence "loop-local string-append copies the accumulated prefix repeatedly; Gerbil and Gambit expose string output ports and byte buffers for linear builders")
         (sourceEvidence "gerbil://std/misc/ports.ss, gerbil://std/misc/string.ss, gerbil://std/net/bio/buffer.ss, gerbil://gambit/tests/unit-tests/13-modules/prim_string.scm")
         (repairStrategies ["output-string-port"
                            "string-join-fragment-list"
                            "u8vector-byte-buffer"
                            "single-boundary-string-append"])
         (next "move string-append out of the loop or replace loop-local string growth with a builder boundary"))))
