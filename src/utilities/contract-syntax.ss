;;; Module boundary: contract syntax owns declaration expansion only; runtime
;;; validation and projection remain ordinary caller-visible dependencies.

(import :gerbil/runtime/gambit
        (for-syntax :gerbil/runtime/gambit))

(export defobject-contract)

;;; Boundary: the syntax layer only emits ordinary Gerbil definitions.
;;; Runtime helpers are resolved in the caller module so import policy can see
;;; real dependencies instead of hidden transformer-phase bindings.

(begin-syntax
  ;; : (-> Symbol String)
  (def (contract-name-fragment name)
    (list->string
     (map (lambda (char) (if (eq? char #\/) #\- char))
          (string->list (symbol->string name)))))

  ;; : (-> SyntaxContext String String SyntaxIdentifier)
  (def (contract-helper-id context prefix suffix)
    (let* ((name (syntax->datum context))
           (fragment (contract-name-fragment name)))
      (datum->syntax context
        (string->symbol (string-append prefix fragment suffix)))))

  ;; : (-> SyntaxContext Symbol SyntaxIdentifier)
  (def (contract-accessor-id context slot)
    (let ((name (syntax->datum context)))
      (datum->syntax context
        (string->symbol
         (string-append (symbol->string name) "-" (symbol->string slot)))))))

;;; Expansion invariant: generated helper identifiers are anchored at the
;;; object name use-site, while declaration keywords remain syntax-only markers.
;;; Intent: let Scheme modules declare contracts once and receive ordinary
;;; Gerbil definitions that policy, tests, and imports can inspect directly.
;; defobject-contract
;;   : (-> ObjectContractDeclaration GerbilDefinitions)
;;   | doc m%
;;       Declares a defstruct plus reusable contract metadata and projection helpers.
;;
;;       # Examples
;;
;;       ```scheme
;;       (defobject-contract type-spec owner: 'types object-kind: 'type-spec slots: ((kind Symbol symbol? required)))
;;       ;; => +type-spec-type-contract+ and require-type-spec-slots!
;;       ```
;;     %
(defsyntax (defobject-contract stx)
  (syntax-case stx ()
    ((_ name _owner-key owner _object-kind-key object-kind _slots-key
        ((slot type predicate presence) ...))
     (let* ((slot-symbols (syntax->datum #'(slot ...)))
            (accessor-ids (map (lambda (slot)
                                 (contract-accessor-id #'name slot))
                               slot-symbols)))
       (with-syntax ((slot-contracts-id
                      (contract-helper-id #'name "+" "-slot-contracts+"))
                     (type-contract-id
                      (contract-helper-id #'name "+" "-type-contract+"))
                     (require-slots-id
                      (contract-helper-id #'name "require-" "-slots!"))
                     (type-contract->alist-id
                      (contract-helper-id #'name "" "-type-contract->alist"))
                     (contract-issues-id
                      (contract-helper-id #'name "" "-contract-issues"))
                     (valid?-id
                      (contract-helper-id #'name "" "-contract-valid?"))
                     (contract-report-rows-id
                      (contract-helper-id #'name "" "-contract-report-rows"))
                     (predicate-id
                      (datum->syntax #'name
                        (string->symbol
                         (string-append (symbol->string (syntax->datum #'name)) "?"))))
                     (make-slot-contract-ref
                      (datum->syntax #'name 'make-slot-contract))
                     (make-object-type-contract-ref
                      (datum->syntax #'name 'make-object-type-contract))
                     (require-object-contract!-ref
                      (datum->syntax #'name 'require-object-contract!))
                     (object-contract-issues-ref
                      (datum->syntax #'name 'object-contract-issues))
                     (object-contract-valid?-ref
                      (datum->syntax #'name 'object-contract-valid?))
                     (object-type-contract->alist-ref
                      (datum->syntax #'name 'object-type-contract->alist))
                     (object-contract-report-rows-ref
                      (datum->syntax #'name 'object-contract-report-rows))
                     ((accessor ...) accessor-ids))
         #'(begin
             (defstruct name (slot ...))
             (def slot-contracts-id
               (list (make-slot-contract-ref 'slot 'type predicate 'presence accessor)
                     ...))
             (def type-contract-id
               (make-object-type-contract-ref owner object-kind predicate-id slot-contracts-id))
             (def (require-slots-id object)
               (require-object-contract!-ref type-contract-id object))
             (def (contract-issues-id object)
               (object-contract-issues-ref type-contract-id object))
             (def (valid?-id object)
               (object-contract-valid?-ref type-contract-id object))
             (def (type-contract->alist-id)
               (object-type-contract->alist-ref type-contract-id))
             (def (contract-report-rows-id object)
               (object-contract-report-rows-ref type-contract-id object))))))))
