;;; -*- Gerbil -*-
;;; POO policy values and typed receipts for macro governance.

(import :gerbil/gambit
        (only-in :clan/poo/object .def .get .o)
        (only-in :std/sugar hash))

(export macro-governance-rule-prototype
        macro-governance-hygiene-rule
        macro-governance-phase-rule
        macro-governance-pattern-budget-rule
        macro-governance-runtime-witness-rule
        macro-governance-expansion-io-rule
        macro-governance-rule-id
        macro-governance-rule-reason-kind
        macro-governance-rule-severity
        macro-governance-profile-prototype
        asp-strict-macro-governance-profile
        macro-governance-profile-name
        macro-governance-profile-rules
        macro-governance-profile-allowed-phases
        macro-governance-profile-require-hygiene?
        macro-governance-profile-max-pattern-count
        macro-governance-profile-rule-enabled?
        make-macro-governance-contract
        macro-governance-contract-macro
        macro-governance-contract-purpose
        macro-governance-contract-capabilities
        macro-governance-decision
        make-macro-governance-decision
        macro-governance-decision?
        macro-governance-decision-macro
        macro-governance-decision-selector
        macro-governance-decision-purpose
        macro-governance-decision-capabilities
        macro-governance-decision-status
        macro-governance-decision-reason-kinds
        macro-governance-decision-json
        macro-governance-receipt
        make-macro-governance-receipt
        macro-governance-receipt?
        macro-governance-receipt-schema-id
        macro-governance-receipt-schema-version
        macro-governance-receipt-profile
        macro-governance-receipt-status
        macro-governance-receipt-macro-count
        macro-governance-receipt-admitted-count
        macro-governance-receipt-rejected-count
        macro-governance-receipt-decisions
        macro-governance-receipt-json)

;; POO rule descriptors are immutable configuration.  Admission compiles their
;; ids into one flat rule plan before walking parser-owned MacroFacts.  V1 keeps
;; executable evaluators closed in the admission module: packages may compose
;; and narrow these values, but package metadata cannot inject policy code.
(.def macro-governance-rule-prototype
  (id #f)
  (reason-kind #f)
  (severity "error"))

(.def (macro-governance-hygiene-rule
       @ macro-governance-rule-prototype)
  (id 'hygiene)
  (reason-kind 'hygiene-required))

(.def (macro-governance-phase-rule
       @ macro-governance-rule-prototype)
  (id 'phase)
  (reason-kind 'phase-not-admitted))

(.def (macro-governance-pattern-budget-rule
       @ macro-governance-rule-prototype)
  (id 'pattern-budget)
  (reason-kind 'pattern-budget-exceeded))

(.def (macro-governance-runtime-witness-rule
       @ macro-governance-rule-prototype)
  (id 'runtime-witness)
  (reason-kind 'executable-witness-required))

(.def (macro-governance-expansion-io-rule
       @ macro-governance-rule-prototype)
  (id 'expansion-io)
  (reason-kind 'expansion-io-denied))

(def (macro-governance-rule-id rule)
  (.get rule id))

(def (macro-governance-rule-reason-kind rule)
  (.get rule reason-kind))

(def (macro-governance-rule-severity rule)
  (.get rule severity))

(.def macro-governance-profile-prototype
  (name 'macro-governance-v1)
  (rules [])
  (allowed-phases ["syntax"])
  (require-hygiene? #t)
  (max-pattern-count 64))

(.def (asp-strict-macro-governance-profile
       @ macro-governance-profile-prototype)
  (name 'asp-strict-v1)
  (rules [macro-governance-hygiene-rule
          macro-governance-phase-rule
          macro-governance-pattern-budget-rule
          macro-governance-runtime-witness-rule
          macro-governance-expansion-io-rule])
  (allowed-phases ["syntax" "match" "import" "export" "import-export"])
  (require-hygiene? #t)
  (max-pattern-count 64))

(def (macro-governance-profile-name profile)
  (.get profile name))

(def (macro-governance-profile-rules profile)
  (.get profile rules))

(def (macro-governance-profile-allowed-phases profile)
  (.get profile allowed-phases))

(def (macro-governance-profile-require-hygiene? profile)
  (.get profile require-hygiene?))

(def (macro-governance-profile-max-pattern-count profile)
  (.get profile max-pattern-count))

(def (macro-governance-profile-rule-enabled? profile id)
  (ormap (lambda (rule)
           (eq? (macro-governance-rule-id rule) id))
         (macro-governance-profile-rules profile)))

;; A contract is a POO value so downstream profiles can extend it without
;; adding new parser syntax.  Its evidence remains parser-owned.
(def (make-macro-governance-contract
      macro-name purpose-value capability-values)
  ;; Parenthesized slot/value pairs capture lexical values.  Keyword slots with
  ;; same-named identifiers are POO self-slot references, so constructor
  ;; formals deliberately use distinct names.
  (.o (macro macro-name)
      (purpose purpose-value)
      (capabilities capability-values)))

(def (macro-governance-contract-macro contract)
  (.get contract macro))

(def (macro-governance-contract-purpose contract)
  (.get contract purpose))

(def (macro-governance-contract-capabilities contract)
  (.get contract capabilities))

;; Decisions and receipts are closed typed data, not extensible policy objects.
(defstruct macro-governance-decision
  (macro selector purpose capabilities status reason-kinds)
  transparent: #t)

(defstruct macro-governance-receipt
  (schema-id schema-version profile status macro-count admitted-count rejected-count decisions)
  transparent: #t)

(def (macro-governance-decision-json decision)
  (hash (macro (macro-governance-decision-macro decision))
        (selector (macro-governance-decision-selector decision))
        (purpose (macro-governance-decision-purpose decision))
        (capabilities (macro-governance-decision-capabilities decision))
        (status (symbol->string (macro-governance-decision-status decision)))
        (reasonKinds
         (map symbol->string
              (macro-governance-decision-reason-kinds decision)))))

(def (macro-governance-receipt-json receipt)
  (hash (schemaId (macro-governance-receipt-schema-id receipt))
        (schemaVersion (macro-governance-receipt-schema-version receipt))
        (profile (symbol->string (macro-governance-receipt-profile receipt)))
        (status (symbol->string (macro-governance-receipt-status receipt)))
        (macroCount (macro-governance-receipt-macro-count receipt))
        (admittedCount (macro-governance-receipt-admitted-count receipt))
        (rejectedCount (macro-governance-receipt-rejected-count receipt))
        (decisions
         (map macro-governance-decision-json
              (macro-governance-receipt-decisions receipt)))))
