;;; -*- Gerbil -*-
;;; Declarative POO family expansion for stable public runtime models.

(import (only-in :clan/poo/object .def .o .ref .slot?))

(export defpoo-object-family
        poo-family-ref)

(def absent-poo-family-slot (cons 'absent-poo-family-slot []))

;; poo-family-ref
;;   : (forall (a) (-> POOObject Symbol a a))
;;   | doc m%
;;       Read one generated POO-family slot.  Missing required slots retain the
;;       native =.ref= failure; callers may supply an explicit default for an
;;       optional projection.
;;
;;       # Examples
;;
;;       ```scheme
;;       (poo-family-ref object 'status 'ready)
;;       ;; => stored status, or 'ready when the slot is absent
;;       ```
;;     %
(def (poo-family-ref value key (default absent-poo-family-slot))
  (if (.slot? value key)
    (.ref value key)
    (if (eq? default absent-poo-family-slot)
      (.ref value key)
      default)))

;; defpoo-object-family
;;   : (-> Prototype Constructor Reader AccessorClauses POOFamilyBindings)
;;   | rationale one declaration owns the native prototype, keyword constructor,
;;       and its public projections without a runtime registry or alist adapter
;;   | doc m%
;;       Generate an ordinary POO prototype, constructor, and accessor family.
;;       Constructor heads and slot expressions remain visible Gerbil syntax;
;;       the macro only removes the repeated structural frame.
;;
;;       # Examples
;;
;;       ```scheme
;;       (defpoo-object-family
;;         (prototype job-prototype (kind 'job))
;;         (constructor (job name: (name "job")) (name name))
;;         (accessors family-ref
;;                    (required (job-name name))
;;                    (optional (job-status status 'ready))))
;;       ;; => job-prototype, job, job-name, and job-status bindings
;;       ```
;;     %
(defrules defpoo-object-family
  (prototype constructor accessors required optional)
  ((_ (prototype prototype-name prototype-slot ...)
      (constructor constructor-head constructor-slot ...)
      (accessors reader
                 (required
                  (required-accessor-name required-accessor-slot) ...)
                 (optional
                  (optional-accessor-name optional-accessor-slot
                                          default-value) ...)))
   (begin
     (.def prototype-name prototype-slot ...)
     (def constructor-head
       (.o (:: @ prototype-name)
           constructor-slot ...))
     (def (required-accessor-name value)
       (reader value 'required-accessor-slot))
     ...
     (def (optional-accessor-name value)
       (reader value 'optional-accessor-slot default-value))
     ...))
  ((_ (prototype prototype-name prototype-slot ...)
      (accessors reader
                 (required
                  (required-accessor-name required-accessor-slot) ...)
                 (optional
                  (optional-accessor-name optional-accessor-slot
                                          default-value) ...)))
   (begin
     (.def prototype-name prototype-slot ...)
     (def (required-accessor-name value)
       (reader value 'required-accessor-slot))
     ...
     (def (optional-accessor-name value)
       (reader value 'optional-accessor-slot default-value))
     ...))
  ((_ (accessors reader
                 (required
                  (required-accessor-name required-accessor-slot) ...)
                 (optional
                  (optional-accessor-name optional-accessor-slot
                                          default-value) ...)))
   (begin
     (def (required-accessor-name value)
       (reader value 'required-accessor-slot))
     ...
     (def (optional-accessor-name value)
       (reader value 'optional-accessor-slot default-value))
     ...)))
