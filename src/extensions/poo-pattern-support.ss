;;; -*- Gerbil -*-
;;; Shared constructors for static Gerbil POO pattern specs.
;;; Boundary:
;;; - Owns slot construction and inheritance for pattern registries.
;;; - Keeps pattern data modules focused on source-backed evidence values.

(import (only-in :clan/poo/object .@ object<-alist)
        )

(export poo-selector
        poo-form-template
        poo-form-mapping
        poo-failure-case
        poo-pattern-object-slot
        make-poo-pattern-spec)

;; : (-> Role Symbol Selector SourceSelector )
(def (poo-selector role symbol selector)
  (hash (role role)
        (symbol symbol)
        (selector selector)))

;; : (-> Head Operands Keywords FormTemplate )
(def (poo-form-template head operands keywords)
  (hash (head head)
        (operands operands)
        (keywords keywords)))

;; : (-> Role Symbol Head Operands Keywords Selector FormMapping )
(def (poo-form-mapping role symbol head operands keywords selector)
  (hash (role role)
        (symbol symbol)
        (template (poo-form-template head operands keywords))
        (selector selector)))

;; : (-> Id RiskKind BadPattern CorrectiveAction Selectors FailureCase )
(def (poo-failure-case id risk-kind bad-pattern corrective-action selectors)
  (hash (id id)
        (riskKind risk-kind)
        (badPattern bad-pattern)
        (correctiveAction corrective-action)
        (selectors selectors)))

;;; Boundary:
;;; - Dynamic public slot lookup is normalized through a stable local helper.
;;; - Packet builders never receive the underlying record representation.
;; : (-> PatternSpec Slot Value )
(def (poo-pattern-object-slot spec slot)
  (case slot
    ((id) (.@ spec id))
    ((defaultFocus) (.@ spec defaultFocus))
    ((sourceOwners) (.@ spec sourceOwners))
    ((agentScenario) (.@ spec agentScenario))
    ((agentSteering) (.@ spec agentSteering))
    ((intent) (.@ spec intent))
    ((selectors) (.@ spec selectors))
    ((minimalForms) (.@ spec minimalForms))
    ((failureCases) (.@ spec failureCases))
    ((qualitySignals) (.@ spec qualitySignals))
    ((witness) (.@ spec witness))
    ((missing) (.@ spec missing))
    ((next) (.@ spec next))
    (else #f)))

;;; Boundary:
;;; - Pattern inheritance keeps slot-level POO override semantics.
;;; - Base specs are package dependency-backed POO objects, not ad hoc records.
;; : (-> PatternSpec Symbol Value Value Value )
(def (poo-pattern-inherit base slot override default)
  (if override
    override
    (if base
      (let (inherited (poo-pattern-object-slot base slot))
        (if inherited inherited default))
      default)))

;;; Boundary:
;;; - This factory materializes one static pattern record.
;;; - Slot defaults and base overrides stay centralized so pattern sections remain declarative.
;; : (-> PatternSpec ... PatternSpec )
(def (make-poo-pattern-spec base: (base #f)
                            id: (id #f)
                            defaultFocus: (defaultFocus #f)
                            sourceOwners: (sourceOwners #f)
                            agentScenario: (agentScenario #f)
                            agentSteering: (agentSteering #f)
                            intent: (intent #f)
                            selectors: (selectors #f)
                            minimalForms: (minimalForms #f)
                            failureCases: (failureCases #f)
                            qualitySignals: (qualitySignals #f)
                            witness: (witness #f)
                            missing: (missing #f)
                            next: (next #f))
  (object<-alist
   [(cons 'id (poo-pattern-inherit base 'id id #f))
    (cons 'defaultFocus (poo-pattern-inherit base 'defaultFocus defaultFocus #f))
    (cons 'sourceOwners (poo-pattern-inherit base 'sourceOwners sourceOwners []))
    (cons 'agentScenario (poo-pattern-inherit base 'agentScenario agentScenario #f))
    (cons 'agentSteering (poo-pattern-inherit base 'agentSteering agentSteering #f))
    (cons 'intent (poo-pattern-inherit base 'intent intent #f))
    (cons 'selectors (poo-pattern-inherit base 'selectors selectors []))
    (cons 'minimalForms (poo-pattern-inherit base 'minimalForms minimalForms []))
    (cons 'failureCases (poo-pattern-inherit base 'failureCases failureCases []))
    (cons 'qualitySignals (poo-pattern-inherit base 'qualitySignals qualitySignals []))
    (cons 'witness (poo-pattern-inherit base 'witness witness #f))
    (cons 'missing (poo-pattern-inherit base 'missing missing []))
    (cons 'next (poo-pattern-inherit base 'next next #f))]))
