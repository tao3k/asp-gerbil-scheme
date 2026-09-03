;;; -*- Gerbil -*-
;;; Parser-owned package metadata facts.

(import :gerbil/gambit
        (only-in :asp-gerbil-scheme/src/parser/support datum-list-items safe-cadr)
        (only-in :std/misc/list unique))

(export read-project-package
        project-package-path
        project-package-name
        project-package-dependencies
        project-package-manager
        project-package-test-directory-policy
        project-package-macro-governance-policy
        project-package-source-scope-policy
        project-package-modularity-policy
        project-package-agent-policy
        project-package-with-source-scope
        test-directory-policy-allowed-directories
        test-directory-policy-explanation
        macro-governance-policy-allow-generated
        macro-governance-policy-explanation
        macro-governance-policy-witness
        source-scope-policy-roots
        source-scope-policy-runtime-roots
        source-scope-policy-exclude-directories
        source-scope-policy-explanation
        modularity-policy-disabled
        modularity-policy-enabled-rules
        modularity-policy-disabled-rules
        modularity-policy-max-source-line-count
        modularity-policy-max-test-line-count
        modularity-policy-min-source-definition-count
        modularity-policy-min-test-definition-count
        modularity-policy-max-test-case-count
        modularity-policy-max-test-definition-span
        modularity-policy-config-path
        modularity-policy-explanation
        agent-policy-disabled-rules
        agent-policy-explanation
        read-package-forms
        package-form?
        package-dependencies
        package-test-directory-policy
        package-macro-governance-policy
        package-source-scope-policy
        package-modularity-policy
        package-agent-policy)
;; TestDirectoryPolicyStruct
(defstruct test-directory-policy (allowed-directories explanation))
;; MacroGovernancePolicyStruct
(defstruct macro-governance-policy (allow-generated explanation witness))
;; SourceScopePolicyStruct
(defstruct source-scope-policy (roots runtime-roots exclude-directories explanation))
;; ModularityPolicyStruct
(defstruct modularity-policy
  (disabled enabled-rules disabled-rules max-source-line-count max-test-line-count min-source-definition-count min-test-definition-count max-test-case-count max-test-definition-span config-path explanation))
;; AgentPolicyStruct
(defstruct agent-policy (disabled-rules explanation))
;; ProjectPackageStruct
(defstruct project-package (path name dependencies manager test-directory-policy macro-governance-policy source-scope-policy modularity-policy agent-policy))

;;; Runtime Build API coverage may refine the source scope after build.ss has
;;; executed.  Preserve every package-owned policy field while replacing only
;;; that projection.
;; : (-> ProjectPackage (List Path) (List Path) (List Path) String ProjectPackage)
(def (project-package-with-source-scope package roots runtime-roots exclude-directories explanation)
  (make-project-package
   (project-package-path package)
   (project-package-name package)
   (project-package-dependencies package)
   (project-package-manager package)
   (project-package-test-directory-policy package)
   (project-package-macro-governance-policy package)
   (make-source-scope-policy roots runtime-roots exclude-directories explanation)
   (project-package-modularity-policy package)
   (project-package-agent-policy package)))
;;; Boundary:
;;; - read-project-package coordinates multiple evidence fields.
;;; - Keep packet shape and invariants stable.
;; : (-> String ParsedData )
(def (read-project-package root)
  (let (package-form (read-package-form root))
    (and package-form
         (make-project-package
          "gerbil.pkg"
          (datum->string (safe-cadr package-form))
          (package-dependencies package-form)
          "gxpkg"
          (package-test-directory-policy package-form)
          (package-macro-governance-policy package-form)
          (package-source-scope-policy package-form)
          (package-modularity-policy root package-form)
          (package-agent-policy package-form)))))
;;; Boundary:
;;; - read-package-form composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> String ParsedData )
(def (read-package-form root)
  (with-catch
   (lambda (_) #f)
   (lambda ()
     (let* ((path (path-expand "gerbil.pkg" root))
            (forms (read-package-forms path)))
       (find package-form? forms)))))
;; read-package-forms
;;   : (-> Path (List Datum))
;;   | doc m%
;;       `read-package-forms path` reads every form from a package or build
;;       source file, preserving source order for policy projection.
;;
;;       # Examples
;;
;;       ```scheme
;;       (read-package-forms "gerbil.pkg")
;;       ;; => package-forms
;;       ```
;;     %
(def (read-package-forms path)
  (call-with-input-file path
    (lambda (port)
      (let lp ((out '()))
        (let (next (read port))
          (if (eof-object? next)
            (reverse out)
            (lp (cons next out))))))))
;; : (-> Datum Boolean )
(def (package-form? datum)
  (and (pair? datum) (eq? (car datum) 'package:)))
;;; Boundary:
;;; - package-dependencies is a field lookup plus dependency string projection.
;;; - Reuse package-field-value so package metadata traversal has one owner.
;; : (-> Datum Integer )
(def (package-dependencies datum)
  (let (deps (package-field-value datum 'depend:))
    (if deps
      (unique (filter-map datum->string (datum-list-items deps)))
      '())))
;; : (-> Datum PackageTestDirectoryPolicy )
(def (package-test-directory-policy datum)
  (let (policy (package-field-value datum 'policy:))
    (and policy
         (let (entry (policy-test-directory-entry policy))
           (and entry
                (make-test-directory-policy
                 (policy-directory-list entry)
                 (policy-string-field entry 'explanation:)))))))
;;; Boundary:
;;; - policy-test-directory-entry composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> Policy PolicyTestDirectoryEntry )
(def (policy-test-directory-entry policy)
  (if (test-directory-policy-form? policy)
    policy
    (find test-directory-policy-form? (datum-list-items policy))))
;; : (-> Datum Boolean )
(def (test-directory-policy-form? datum)
  (and (pair? datum)
       (member (car datum) '(test-directory-layout test-directory-policy))))
;; : (-> Datum PackageMacroGovernancePolicy )
(def (package-macro-governance-policy datum)
  (let (policy (package-field-value datum 'policy:))
    (and policy
         (let (entry (policy-macro-governance-entry policy))
           (and entry
                (make-macro-governance-policy
                 (policy-boolean-field entry 'allow-generated:)
                 (policy-string-field entry 'explanation:)
                 (policy-string-field entry 'witness:)))))))
;;; Boundary:
;;; - policy-macro-governance-entry composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> Policy PolicyMacroGovernanceEntry )
(def (policy-macro-governance-entry policy)
  (if (macro-governance-policy-form? policy)
    policy
    (find macro-governance-policy-form? (datum-list-items policy))))
;; : (-> Datum Boolean )
(def (macro-governance-policy-form? datum)
  (and (pair? datum)
       (member (car datum) '(macro-governance macro-policy))))
;; : (-> Datum String )
(def (package-source-scope-policy datum)
  (let (policy (package-field-value datum 'policy:))
    (and policy
         (let (entry (policy-source-scope-entry policy))
           (and entry
                (make-source-scope-policy
                 (or (policy-string-list-field entry 'roots:)
                     (policy-string-list-field entry 'source-roots:)
                     (policy-string-list-field entry 'source-root:)
                     '())
                 (or (policy-string-list-field entry 'runtime-roots:)
                     (policy-string-list-field entry 'runtime-root:)
                     '())
                 (or (policy-string-list-field entry 'exclude-directories:)
                     (policy-string-list-field entry 'excluded-directories:)
                     (policy-string-list-field entry 'ignore-directories:)
                     '())
                 (policy-string-field entry 'explanation:)))))))
;;; Boundary:
;;; - policy-source-scope-entry composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> Policy String )
(def (policy-source-scope-entry policy)
  (if (source-scope-policy-form? policy)
    policy
    (find source-scope-policy-form? (datum-list-items policy))))
;; : (-> Datum Boolean )
(def (source-scope-policy-form? datum)
  (and (pair? datum)
       (member (car datum) '(source-scope source-policy project-resolution))))
;; : (-> Root Datum PackageModularityPolicy )
(def (package-modularity-policy root datum)
  (let* ((policy (package-field-value datum 'policy:))
         (entry (and policy (policy-modularity-entry policy)))
         (inline-policy (and entry (modularity-policy-entry->policy entry #f)))
         (config-policy
          (and inline-policy
               (modularity-policy-config-path inline-policy)
               (read-modularity-policy-config
                root
                (modularity-policy-config-path inline-policy)))))
    (merge-modularity-policies inline-policy config-policy)))
;;; Boundary:
;;; - policy-modularity-entry composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> Policy PolicyModularityEntry )
(def (policy-modularity-entry policy)
  (if (modularity-policy-form? policy)
    policy
    (find modularity-policy-form? (datum-list-items policy))))
;; : (-> Datum Boolean )
(def (modularity-policy-form? datum)
  (and (pair? datum)
       (member (car datum) '(modularity modularity-policy modularity-rules))))
;;; Boundary:
;;; - modularity-policy-entry->policy owns package field normalization.
;;; - Keep threshold aliases and config-file semantics visible here.
;; : (-> Datum MaybePath PackageModularityPolicy )
(def (modularity-policy-entry->policy entry config-path)
  (make-modularity-policy
   (or (policy-boolean-field entry 'disabled:)
       (policy-boolean-field entry 'disable:))
   (or (policy-string-list-field entry 'enabled-rules:)
       (policy-string-list-field entry 'enable:)
       '())
   (or (policy-string-list-field entry 'disabled-rules:)
       (policy-string-list-field entry 'disable:)
       '())
   (policy-line-count-field*
    entry
    '(max-source-lines: max-source-line-count: source-max-lines:))
   (policy-line-count-field*
    entry
    '(max-test-lines: max-test-line-count: test-max-lines:))
   (policy-integer-field*
    entry
    '(min-source-definitions: min-source-definition-count:))
   (policy-integer-field*
    entry
    '(min-test-definitions: min-test-definition-count:))
   (policy-integer-field*
    entry
    '(max-test-cases: max-test-case-count: test-case-max:))
   (policy-integer-field*
    entry
    '(max-test-definition-span: test-definition-span-max:))
   (or (policy-string-field entry 'config:)
       (policy-string-field entry 'config-file:)
       (policy-string-field entry 'path:)
       config-path)
   (policy-string-field entry 'explanation:)))
;;; Boundary:
;;; - read-modularity-policy-config reads the package-selected external file.
;;; - Missing or malformed config stays a package-policy absence, not a fallback.
;; : (-> Root ConfigPath PackageModularityPolicy )
(def (read-modularity-policy-config root config-path)
  (with-catch
   (lambda (_) #f)
   (lambda ()
     (let* ((path (path-expand config-path root))
            (forms (read-package-forms path))
            (entry (find modularity-policy-form? forms)))
       (and entry
            (modularity-policy-entry->policy entry config-path))))))
;;; Boundary:
;;; - merge-modularity-policies lets gerbil.pkg override shared config values.
;;; - Keep list overrides explicit so agent-facing rule filters stay readable.
;; : (-> MaybePolicy MaybePolicy PackageModularityPolicy )
(def (merge-modularity-policies inline-policy config-policy)
  (cond
   ((and inline-policy config-policy)
    (make-modularity-policy
     (or (modularity-policy-disabled inline-policy)
         (modularity-policy-disabled config-policy))
     (policy-list-override
      (modularity-policy-enabled-rules inline-policy)
      (modularity-policy-enabled-rules config-policy))
     (policy-list-override
      (modularity-policy-disabled-rules inline-policy)
      (modularity-policy-disabled-rules config-policy))
     (or (modularity-policy-max-source-line-count inline-policy)
         (modularity-policy-max-source-line-count config-policy))
     (or (modularity-policy-max-test-line-count inline-policy)
         (modularity-policy-max-test-line-count config-policy))
     (or (modularity-policy-min-source-definition-count inline-policy)
         (modularity-policy-min-source-definition-count config-policy))
     (or (modularity-policy-min-test-definition-count inline-policy)
         (modularity-policy-min-test-definition-count config-policy))
     (or (modularity-policy-max-test-case-count inline-policy)
         (modularity-policy-max-test-case-count config-policy))
     (or (modularity-policy-max-test-definition-span inline-policy)
         (modularity-policy-max-test-definition-span config-policy))
     (or (modularity-policy-config-path inline-policy)
         (modularity-policy-config-path config-policy))
     (or (modularity-policy-explanation inline-policy)
         (modularity-policy-explanation config-policy))))
   (inline-policy inline-policy)
   (else config-policy)))
;;; Boundary:
;;; - policy-list-override keeps rule-list precedence separate from scalars.
;;; - Empty primary lists intentionally fall through to the config file list.
;; : (-> (List String) (List String) (List String) )
(def (policy-list-override primary fallback)
  (if (and primary (pair? primary))
    primary
    (or fallback '())))
;; : (-> Datum Boolean )
(def (quoted-datum? datum)
  (and (pair? datum) (eq? (car datum) 'quote)))

;; : (-> Datum PackageAgentPolicy )
(def (package-agent-policy datum)
  (let (policy (package-field-value datum 'policy:))
    (and policy
         (let (entry (policy-agent-entry policy))
           (and entry
                (make-agent-policy
                 (or (policy-string-list-field entry 'disabled-rules:)
                     (policy-string-list-field entry 'disable:)
                     '())
                 (policy-string-field entry 'explanation:)))))))
;;; Boundary:
;;; - policy-agent-entry composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> Policy PolicyAgentEntry )
(def (policy-agent-entry policy)
  (if (agent-policy-form? policy)
    policy
    (find agent-policy-form? (datum-list-items policy))))
;; : (-> Datum Boolean )
(def (agent-policy-form? datum)
  (and (pair? datum)
       (member (car datum) '(agent-policy policy-rules))))
;; : (-> Datum PolicyDirectoryList )
(def (policy-directory-list datum)
  (or (policy-string-list-field datum 'allowed-directories:)
      (policy-string-list-field datum 'allow-directories:)
      (policy-string-list-field datum 'allow:)
      '()))
;;; Boundary:
;;; - policy-string-list-field composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> Datum String String )
(def (policy-string-list-field datum field)
  (let (value (package-field-value datum field))
    (policy-string-list-value value)))

;; : (-> Datum StringListField )
(def (policy-string-list-value value)
  (cond
   ((not value) #f)
   ((quoted-datum? value) (policy-string-list-value (safe-cadr value)))
   ((or (string? value) (symbol? value)) [(datum->string value)])
   (else (unique (filter-map datum->string (datum-list-items value))))))
;; : (-> Datum String String )
(def (policy-string-field datum field)
  (let (value (package-field-value datum field))
    (and value (datum->string value))))
;; : (-> Datum String PolicyBooleanField )
(def (policy-boolean-field datum field)
  (let (value (package-field-value datum field))
    (truthy-policy-value? value)))
;;; Boundary:
;;; - policy-integer-field* checks aliases in declared precedence order.
;;; - Use parser-owned package fields instead of string scanning.
;; : (-> Datum (List Symbol) Integer )
(def (policy-integer-field* datum fields)
  (ormap (cut policy-integer-field datum <>) fields))

;; : Integer
(def +modularity-hard-max-line-count+ 1000)

;;; Boundary:
;;; - Modularity line limits are capped as package metadata is parsed.
;;; - Downstream policy objects must not carry >1000 owner-line budgets.
;; : (-> Datum (List Symbol) Integer )
(def (policy-line-count-field* datum fields)
  (let (value (policy-integer-field* datum fields))
    (and value
         (min value +modularity-hard-max-line-count+))))

;;; Boundary:
;;; - policy-integer-field normalizes numeric package policy values.
;;; - Keep invalid or absent values false so callers can use defaults.
;; : (-> Datum Symbol Integer )
(def (policy-integer-field datum field)
  (let (value (package-field-value datum field))
    (cond
     ((not value) #f)
     ((integer? value) value)
     (else
      (let (parsed (string->number (datum->string value)))
        (and (integer? parsed) parsed))))))
;; : (-> PolicyValue Boolean )
(def (truthy-policy-value? value)
  (if (or (eq? value #t)
          (member (datum->string value) '("true" "yes" "allow" "allowed")))
    #t
    #f))
;; package-field-value
;;   : (-> Datum Symbol (U #f Datum))
;;   | doc m%
;;       `package-field-value datum field` returns the datum immediately after a
;;       package field marker, or `#f` when the field is absent.
;;
;;       # Examples
;;
;;       ```scheme
;;       (package-field-value '(package: name "demo") 'name)
;;       ;; => "demo"
;;       ```
;;     %
(def (package-field-value datum field)
  (let (tail (member field (datum-list-items datum)))
    (and tail
         (pair? (cdr tail))
         (cadr tail))))
;; datum->string
;;   : (-> Obj (U #f String))
;;   | doc m%
;;       `datum->string obj` converts package datums into comparable string
;;       values, preserving `#f` for absent data.
;;
;;       # Examples
;;
;;       ```scheme
;;       (datum->string 'allow)
;;       ;; => "allow"
;;       ```
;;     %
(def (datum->string obj)
  (cond
   ((not obj) #f)
   ((string? obj) obj)
   ((symbol? obj) (symbol->string obj))
   (else (call-with-output-string "" (cut display obj <>)))))
