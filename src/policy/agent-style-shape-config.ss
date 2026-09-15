;;; -*- Gerbil -*-
;;; Evidence thresholds and source-backed repair vocabulary for shape policy.

(import :gerbil/gambit)

(export +field-access-helper-evidence-min-access-count+
        +field-access-helper-evidence-min-caller-count+
        +projection-burst-min-access-count+
        +projection-burst-min-field-count+
        +projection-burst-min-emitter-count+
        +boolean-condition-combinator-min-condition-count+
        +controlled-branch-shape-conditional-dispatch-min-count+
        +controlled-branch-shape-stateful-callees+
        +controlled-branch-shape-source-backed-owners+
        +controlled-branch-shape-source-backed-repair-candidates+)

;; Integer
(def +field-access-helper-evidence-min-access-count+ 8)
;; Integer
(def +field-access-helper-evidence-min-caller-count+ 3)
;; Integer
(def +projection-burst-min-access-count+ 12)
;; Integer
(def +projection-burst-min-field-count+ 4)
;; Integer
(def +projection-burst-min-emitter-count+ 2)
;; Integer
(def +boolean-condition-combinator-min-condition-count+ 5)
;; Integer
(def +controlled-branch-shape-conditional-dispatch-min-count+ 4)
;; (List CalleeName)
(def +controlled-branch-shape-stateful-callees+
  '("set!" "set-car!" "set-cdr!" "vector-set!" "hash-put!" "hash-remove!"
    "hash-clear!" "table-set!" "table-delete!" ".put!" ".slot-set!"))

;;; Source owner anchors:
;;; - These references come from the declared gerbil-utils evidence corpus.
;;; - Policy details retain them so repair suggestions remain attributable.
;; (List SourceOwner)
(def +controlled-branch-shape-source-backed-owners+
  ["gerbil-utils/base.ss#lambda-match/lambda-ematch"
   "gerbil-utils/base.ss#fun"
   "gerbil-utils/base.ss#cut/curry/rcurry"
   "gerbil-utils/base.ss#compose/rcompose/!>/!!>"
   "gerbil-utils/base.ss#case-lambda specializers"
   "gerbil-utils/generator.ss#compose-backed-generating-map"])

;;; Repair candidate contract:
;;; - Candidate order moves from syntax-specific idioms to plain helpers.
;;; - Parser facts still decide which choice is admissible for one finding.
;; (List RepairMove)
(def +controlled-branch-shape-source-backed-repair-candidates+
  ["lambda-match/lambda-ematch for unary match destructuring"
   "fun for reusable local named lambda boundaries"
   "cut/curry/rcurry for first-class argument specialization"
   "compose/rcompose/!>/!!> for reusable expression pipelines"
   "case-lambda only when there are real arity specializations"
   "plain named helpers only when no higher-order Gerbil idiom fits"])
