;;; Module boundary: runtime contract records are plain Gerbil values shared by
;;; syntax expansion, projections, tests, and policy reports.

(import (only-in :std/list/list filter-map)
        :gerbil/runtime/gambit)

(export make-slot-contract
        slot-contract?
        slot-contract-name
        slot-contract-type
        slot-contract-predicate
        slot-contract-presence
        slot-contract-accessor
        make-object-type-contract
        object-type-contract?
        object-type-contract-owner
        object-type-contract-object-kind
        object-type-contract-predicate
        object-type-contract-slots
        make-contract-issue
        contract-issue?
        contract-issue-code
        contract-issue-slot
        contract-issue-message
        required-slot-contract?
        object-contract-issues
        object-contract-valid?
        require-object-contract!)

;;; Boundary: slot contracts keep declared shape close to generated defstruct
;;; accessors.  The accessor is data, not syntax, so downstream policy checks
;;; validate runtime values without re-parsing the macro declaration.
;; : SlotContractRecord
(defstruct slot-contract (name type predicate presence accessor))

;;; Invariant: object contracts stay plain structs so reporting and policy tests
;;; do not depend on macro internals.
;; : ObjectTypeContractRecord
(defstruct object-type-contract (owner object-kind predicate slots))

;;; Invariant: issues are compact symbolic payloads suitable for test output and
;;; agent-facing diagnostics.
;; : ContractIssueRecord
(defstruct contract-issue (code slot message))

;;; Intent: keep presence checks explicit instead of spreading raw symbol tests.
;;; | doc m% Tells whether the slot was declared as required in the contract DSL.
;;; # Examples: required slot metadata => #t.
;; : (-> SlotContract Boolean)
(def (required-slot-contract? contract)
  (eq? (slot-contract-presence contract) 'required))

;;; Intent: localize predicate failure construction to one helper.
;;; | doc m% Runs one slot predicate against the value reached by its accessor.
;;; # Examples: a valid Number type kind slot => #f.
;; : (-> SourceObject SlotContract MaybeContractIssue)
(def (slot-contract-issue object contract)
  (let* ((slot (slot-contract-name contract))
         (value ((slot-contract-accessor contract) object))
         (predicate (slot-contract-predicate contract)))
    (if (predicate value)
      #f
      (make-contract-issue 'slot-predicate slot "slot predicate failed"))))

;;; Validation order: reject the object kind before reading generated accessors.
;;; | doc m% Validates the object predicate first, then checks declared slots.
;;; # Examples: (object-contract-issues +type-spec-type-contract+ number-type) => ().
;; : (-> ObjectTypeContract SourceObject (List ContractIssue))
(def (object-contract-issues contract object)
  (if ((object-type-contract-predicate contract) object)
    (filter-map (lambda (slot) (slot-contract-issue object slot))
                (object-type-contract-slots contract))
    (list (make-contract-issue 'object-kind
                               (object-type-contract-object-kind contract)
                               "object predicate failed"))))

;;; Intent: expose a boolean predicate for callers that only need pass/fail.
;;; | doc m% Returns true when no object or slot issue is reported.
;;; # Examples: (object-contract-valid? +type-spec-type-contract+ number-type) => #t.
;; : (-> ObjectTypeContract SourceObject Boolean)
(def (object-contract-valid? contract object)
  (null? (object-contract-issues contract object)))

;;; Failure boundary: callers get the original object on success and a compact
;;; error payload on failure, which keeps downstream tests from inspecting
;;; private contract struct layout.
;;; | doc m% Returns the original object or raises a compact contract failure.
;;; # Examples: (require-object-contract! +type-spec-type-contract+ number-type) => number-type.
;; : (-> ObjectTypeContract SourceObject SourceObject)
(def (require-object-contract! contract object)
  (let (issues (object-contract-issues contract object))
    (if (null? issues)
      object
      (error "object contract failed"
             (object-type-contract-object-kind contract)
             (map contract-issue-code issues)))))
;;; Contract records are the runtime boundary for generated harness schemas.
;;; Keep validation results structured as contract issues so callers can report
;;; policy evidence without depending on exception text or syntax-layer details.
