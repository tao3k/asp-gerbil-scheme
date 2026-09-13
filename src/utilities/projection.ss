;;; Module boundary: projection converts contract records into stable symbolic
;;; packets and intentionally drops procedures from public report rows.

(import (only-in :asp-gerbil-scheme/src/utilities/contracts
                 slot-contract-name
                 slot-contract-type
                 slot-contract-presence
                 slot-contract-predicate
                 slot-contract-accessor
                 object-type-contract-owner
                 object-type-contract-object-kind
                 object-type-contract-predicate
                 object-type-contract-slots)
        :gerbil/gambit)

(export slot-contract->alist
        object-type-contract->alist
        object-contract-report-rows)

;;; Boundary: projection keeps the contract runtime inspectable by tests and
;;; search output.  Rows avoid embedding predicate/accessor procedures because
;;; those values are not stable across compilation modes.

;;; Intent: make slot metadata serializable without exposing procedures.
;;; | doc m% Converts a slot contract into a stable symbolic row.
;;; # Examples: slot metadata => ((name . kind) (type . Symbol) ...).
;; : (-> SlotContract SlotContractMetadataAlist)
(def (slot-contract->alist contract)
  `((name . ,(slot-contract-name contract))
    (type . ,(slot-contract-type contract))
    (presence . ,(slot-contract-presence contract))))

;;; Intent: project object-level metadata and slot rows in one stable packet.
;;; | doc m% Projects object contract metadata and declared slot rows.
;;; # Examples: owner lookup on type-spec contract => (owner . types).
;; : (-> ObjectTypeContract ObjectTypeContractMetadataAlist)
(def (object-type-contract->alist contract)
  `((owner . ,(object-type-contract-owner contract))
    (object-kind . ,(object-type-contract-object-kind contract))
    (slots . ,(map slot-contract->alist
                   (object-type-contract-slots contract)))))

;;; Intent: keep validation rows symbolic so scenario assertions stay stable.
;;; | doc m% Builds one validation row for policy and scenario assertions.
;;; # Examples: valid kind slot report => (status . ok).
;; : (-> SlotContract ContractRuntimeObject SlotValidationReportAlist)
(def (slot-contract-report-row contract object)
  (let* ((value ((slot-contract-accessor contract) object))
         (status (if ((slot-contract-predicate contract) value) 'ok 'invalid)))
    `((slot . ,(slot-contract-name contract))
      (type . ,(slot-contract-type contract))
      (presence . ,(slot-contract-presence contract))
      (status . ,status))))

;;; Report invariant: valid objects produce one row per declared slot; invalid
;;; objects produce one object-level row so callers can keep a uniform list API.
;;; | doc m% Reports per-slot status when the object matches the declared kind.
;;; # Examples: type-spec rows => (kind name params result).
;; : (-> ObjectTypeContract ContractRuntimeObject ContractValidationReportRows)

;; object-contract-report-rows
;;   : (-> ObjectTypeContract SourceObject (List ContractReportRow))
;;   | doc m%
;;   # Examples
;;   ```scheme
;;   (object-contract-report-rows contract object)
;;   ;; => slot report rows or an object-level invalid row
;;   ```
;;   Result: returns slot rows, or one object-level invalid row when kind fails.
(def (object-contract-report-rows contract object)
  (if ((object-type-contract-predicate contract) object)
    (map (lambda (slot) (slot-contract-report-row slot object))
         (object-type-contract-slots contract))
    (list `((slot . object)
            (type . ,(object-type-contract-object-kind contract))
            (presence . required)
            (status . invalid)))))
;;; Projection utilities convert contract records and validation status into
;;; stable alists. This is the reporting boundary consumed by policy checks,
;;; so callers should not reconstruct rows from struct accessors directly.
