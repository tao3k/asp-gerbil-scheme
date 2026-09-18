;;; -*- Gerbil -*-
;;; Agent-facing self-audit for anonymous result pair access.
;;; Repeated car/cdr over a value named result is a test-quality smell: the
;;; command boundary may return a pair, but call sites should use named accessors.

(import :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/policy/model
        (only-in :std/sugar filter hash ormap)
        :asp-gerbil-scheme/src/types/findings)

(export anonymous-pair-access-findings
        anonymous-pair-access-finding)

;; Integer
(def +anonymous-pair-access-min-calls+ 6)

;;; Project traversal boundary:
;;; - Parser call facts expose pair operations.
;;; - This rule is intentionally narrow: repeated result tuple access in tests.
;; : (-> ProjectIndex (List TypeFinding) )
(def (anonymous-pair-access-findings index)
  (filter-map anonymous-pair-access-finding
              (project-index-files index)))

;;; Threshold boundary:
;;; - One or two bridge helpers are acceptable.
;;; - Repetition across tests means the result shape needs named accessors.
;; : (-> SourceFile MaybeTypeFinding )
(def (anonymous-pair-access-finding file)
  (let (calls (anonymous-result-pair-access-calls file))
    (and (anonymous-result-pair-access-triggered? calls)
         (make-type-finding
          (policy-rule-id +agent-anonymous-pair-access-rule+)
          (policy-rule-severity +agent-anonymous-pair-access-rule+)
          (source-file-path file)
          "repeated car/cdr over anonymous result pairs hides test data shape; introduce named result accessors or a small record"
          (call-fact-selector (car calls))
          (anonymous-pair-access-details calls)))))

;;; Trigger predicate:
;;; - Both car and cdr must be present.
;;; - The repeated-call threshold avoids warning on one compatibility bridge.
;; : (-> (List CallFact) Boolean )
(def (anonymous-result-pair-access-triggered? calls)
  (and (>= (length calls) +anonymous-pair-access-min-calls+)
       (ormap (lambda (call)
                (equal? (call-fact-callee call) "car"))
              calls)
       (ormap (lambda (call)
                (equal? (call-fact-callee call) "cdr"))
              calls)))

;;; Access collection:
;;; - Only test owners are checked.
;;; - Only direct operations on a variable named result are counted.
;; : (-> SourceFile (List CallFact) )
(def (anonymous-result-pair-access-calls file)
  (if (anonymous-pair-test-source-file? file)
    (filter anonymous-result-pair-access-call?
            (source-file-calls file))
    []))

;;; Test source scope:
;;; - This catches low-quality test receipts without banning list processing.
;;; - Runtime data structures should use more specific rules.
;; : (-> SourceFile Boolean )
(def (anonymous-pair-test-source-file? file)
  (let (path (source-file-path file))
    (and path
         (equal? (source-path-class path) "test"))))

;;; Parser call predicate:
;;; - car/cdr must be the callee.
;;; - The first argument must be exactly the anonymous result value.
;; : (-> CallFact Boolean )
(def (anonymous-result-pair-access-call? call)
  (and (member (call-fact-callee call) ["car" "cdr"])
       (let (arguments (call-fact-arguments call))
         (and (pair? arguments)
              (equal? (car arguments) "result")))))

;;; Details boundary:
;;; - Finding details stay plain hash data for provider output.
;;; - Selectors show every repeated test access that should use an accessor.
;; : (-> (List CallFact) PolicyDetails )
(def (anonymous-pair-access-details calls)
  (hash (kind "anonymous-result-pair-access")
        (accessCount (length calls))
        (selectors (map call-fact-selector calls))
        (repair "replace repeated (car result)/(cdr result) with result-specific accessors or a small record")))
