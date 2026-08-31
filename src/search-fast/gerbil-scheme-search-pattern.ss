;;; -*- Gerbil -*-
;;; Fast pattern search packet emitter for Gerbil POO guidance.
;;; Keeps startup dependency-light so pattern lookup stays below agent latency budget.
;;; Leaves protocol rows explicit because agents depend on stable line-oriented fields.
(import :gerbil/gambit
        (only-in :std/srfi/13 string-join string-suffix?))
(export main)

;; : (-> Unit String )
(def +poo-dependency+ "git.cons.io/mighty-gerbils/gerbil-poo")

;; : (-> (List String) Unit )
(def (emit . parts)
  (for-each display parts)
  (newline))

;; : (-> String Boolean )
(def (option-with-value? arg)
  (or (equal? arg "--view")
      (equal? arg "--workspace")))

;; : (-> (List String) (List String) (List String) )
(def (collect-positional-args rest out)
  (cond
   ((null? rest) (reverse out))
   ((option-with-value? (car rest))
    (collect-positional-args (if (pair? (cdr rest)) (cddr rest) '()) out))
   ((equal? (car rest) "--json")
    (collect-positional-args (cdr rest) out))
   (else (collect-positional-args (cdr rest) (cons (car rest) out)))))

;; : (-> (List String) (List String) )
(def (positional-args args)
  (collect-positional-args args '()))

;; : (-> String Boolean )
(def (identity-token? term)
  (or (equal? term "gerbil-poo")
      (equal? term +poo-dependency+)))

;; : (-> (List String) String Boolean )
(def (has-term? terms target)
  (member target terms))

;; : (-> MaybePathString Boolean )
(def (source-script-path? value)
  (and (string? value)
       (or (string-suffix? ".ss" value)
           (string-suffix? ".inc" value))))

;; : (-> Unit (List String) )
(def (entry-args)
  (let (args (command-line))
    (if (and (pair? args)
             (pair? (cdr args))
             (source-script-path? (cadr args)))
      (cddr args)
      (cdr args))))

;;; Boundary: extension identity tokens are stripped before choosing pattern focus.
;; : (-> (List String) String )
(def (focus terms)
  (let (rest (filter (lambda (term) (not (identity-token? term))) terms))
    (if (null? rest) "usage" (string-join rest " "))))

;; : (-> Unit Unit )
(def (emit-common-source-lookup)
  (emit "|selectorResolver scheme=gerbil-poo-logical-symbol status=logical-selector"
        " querySelector=not-direct"
        " sourceRef=package-manager-source:gxpkg:" +poo-dependency+ ":runtime-resolved")
  (emit "|sourceLookup order=local-source-before-git"
        " missingLocalAction=install-package-before-repository-fallback"
        " fallbackPolicy=repository-source-after-install-check"
        " localRootHint=~/.gerbil"
        " localPackage=" +poo-dependency+
        " localStatus=probe-first"
        " localMissingAction=install-package-before-repository-fallback"
        " installHint=\"gxpkg install " +poo-dependency+ "\""
        " repository=" +poo-dependency+
        " repositoryUrl=https://git.cons.io/mighty-gerbils/gerbil-poo"
        " indexOwner=asp-server"
        " indexBackend=rust-sql"
        " indexPackageManager=gxpkg")
  (emit "|agentReadOrder first=agentScenario second=agentSteering third=selectorResolver fourth=minimalForms fifth=failureCases sixth=quality")
  (emit "|agentAction action=use-minimalForms-before-editing selectorUse=source-anchor missingLocalAction=install-package-before-repository-fallback fallback=repository-source-after-install-check quality=verified avoid=generic-scheme-or-racket-class-guess"))

;;; Boundary: object-system output owns the selector and minimal-form packet rows.
;; : (-> String String Unit )
(def (emit-object-system-pattern query pattern-focus)
  (emit "[gerbil-search-pattern] query=" query
        " evidenceGrade=fact authority=executable-pattern quality=verified")
  (emit "|pattern id=poo-object-system extension=poo focus=" pattern-focus
        " origin=registered via=-"
        " sourceRef=package-manager-source:gxpkg:" +poo-dependency+ ":runtime-resolved"
        " witness=dependency-backed-poo-mapping")
  (emit-common-source-lookup)
  (emit "|agentScenario id=agent-does-not-know-gerbil-poo-object-system intent=write-gerbil-poo-object-system-without-racket-or-generic-scheme-guessing")
  (emit "|agentSteering follow the emitted selectors and minimal forms before writing Gerbil POO code; avoid Racket class or generic Scheme object guesses")
  (emit "|selector role=class-definition symbol=defclass selector=gerbil-poo://object.ss#defclass")
  (emit "|selector role=generic-definition symbol=.defgeneric selector=gerbil-poo://mop.ss#.defgeneric")
  (emit "|selector role=method-dispatch symbol=defmethod selector=gerbil-poo://mop.ss#defmethod")
  (emit "|selector role=protocol-composition symbol=proto selector=gerbil-poo://mop.ss#proto")
  (emit "|selector role=prototype-composition symbol=compose-proto selector=gerbil-poo://proto.ss#compose-proto")
  (emit "|selector role=thin-macro-bridge symbol=@method selector=gerbil-poo://brace.ss#@method")
  (emit "|selector role=slot-resolution symbol=compute-precedence-list! selector=gerbil-poo://object.ss#compute-precedence-list!")
  (emit "|selector role=slot-cache symbol=compute-slot-funs! selector=gerbil-poo://object.ss#compute-slot-funs!")
  (emit "|selector role=io-serialization-method-family symbol=marshal selector=gerbil-poo://io.ss#marshal")
  (emit "|selector role=method-resolution-order symbol=class-precedence-list selector=gerbil-runtime://c3.ss#class-precedence-list")
  (emit "|selector role=real-project-semantic-test symbol=c3-test selector=gerbil-runtime-test://src/gerbil/test/c3-test.ss#c3-test")
  (emit "|form role=class-definition symbol=defclass head=defclass operands=(<Class> <Base>),(<slot> ...) keywords=transparent: #t selector=gerbil-poo://object.ss#defclass")
  (emit "|form role=generic-definition symbol=.defgeneric head=.defgeneric operands=(<generic> <type> <arg>) keywords=slot: .<slot> selector=gerbil-poo://mop.ss#.defgeneric")
  (emit "|form role=method-dispatch symbol=defmethod head=defmethod operands=(@@method <generic> <type>),(lambda (self) ...) keywords= selector=gerbil-poo://mop.ss#defmethod")
  (emit "|form role=protocol-composition symbol=compose-proto head=compose-proto operands=<proto-a>,<proto-b> keywords= selector=gerbil-poo://proto.ss#compose-proto")
  (emit "|form role=thin-macro-bridge symbol=@method head=defsyntax-for-match operands={args ...}->.o/ctx keywords=syntax-bridge-only selector=gerbil-poo://brace.ss#@method")
  (emit "|form role=slot-resolution symbol=.all-slots head=.all-slots operands=<object> keywords=C3-precedence,lazy-slot-cache selector=gerbil-poo://object.ss#.all-slots")
  (emit "|form role=io-serialization-method-family symbol=marshal head=.defgeneric operands=(marshal type x port),slot:.marshal keywords=json<-,<-json,bytes<-,<-bytes selector=gerbil-poo://io.ss#marshal")
  (emit "|form role=mro-regression-test symbol=class-precedence-list head=check operands=(map ##type-name (class-precedence-list <Class>::t)),'(<Class> <Base> ... object t) keywords= selector=gerbil-runtime-test://src/gerbil/test/c3-test.ss#class-inheritance")
  (emit "|form role=slot-order-regression-test symbol=class-type-slot-vector head=check operands=(class-type-slot-vector <Class>::t),#(__class <base-slots> ... <class-slots> ...) keywords= selector=gerbil-runtime-test://src/gerbil/test/c3-test.ss#slot-computation-order")
  (emit "|failureCase id=racket-class-syntax risk=dialect-confusion correction=use-poo-form-mapping")
  (emit "|failureCase id=missing-extension-activation risk=inactive-extension correction=query-extension-before-pattern")
  (emit "|failureCase id=method-without-generic risk=incomplete-method-contract correction=follow-generic-and-method-mappings-together")
  (emit "|failureCase id=unchecked-mro-assumption risk=semantic-regression-gap correction=add-c3-linearization-and-slot-vector-witnesses")
  (emit "|failureCase id=macro-bridge-with-runtime-semantics risk=macro-overreach correction=keep-brace-syntax-thin-and-put-semantics-in-object-or-mop-slots")
  (emit "|failureCase id=direct-slot-hash-guess risk=missing-c3-and-lazy-slot-resolution correction=query-object-slot-resolution-before-editing")
  (emit "|failureCase id=io-method-without-family risk=serializer-or-printer-drift correction=follow-json-marshal-bytes-method-family-and-runtime-source-witnesses")
  (emit "|qualitySignal id=gerbil-poo-logical-selector-registry")
  (emit "|qualitySignal id=dependency-backed-mapping")
  (emit "|qualitySignal id=real-project-c3-test")
  (emit "|qualitySignal id=mro-linearization-witness")
  (emit "|qualitySignal id=slot-order-witness")
  (emit "|qualitySignal id=thin-macro-bridge")
  (emit "|qualitySignal id=object-slot-resolution-model")
  (emit "|qualitySignal id=io-serialization-method-family")
  (emit "|qualitySignal id=minimal-forms")
  (emit "|qualitySignal id=failure-cases")
  (emit "|quality verified missing=- selectorCount=11 formCount=9 failureCaseCount=7")
  (emit "next=search extension gerbil-poo " pattern-focus))

;;; Boundary: rationaldict output owns the adapter and precise-import packet rows.
;; : (-> String String Unit )
(def (emit-rationaldict-pattern query pattern-focus)
  (emit "[gerbil-search-pattern] query=" query
        " evidenceGrade=fact authority=executable-pattern quality=verified")
  (emit "|pattern id=poo-rationaldict-adapter extension=poo focus=" pattern-focus
        " origin=direct via=-"
        " sourceRef=package-manager-source:gxpkg:" +poo-dependency+ ":runtime-resolved"
        " witness=gerbil-poo-rationaldict-adapter-source-shape")
  (emit-common-source-lookup)
  (emit "|agentScenario id=agent-wraps-dependency-primitives-without-a-typed-protocol-adapter intent=query-rationaldict-adapter-shape-before-writing-dependency-backed-table-or-dict-boundaries")
  (emit "|agentSteering dependency already owns the storage primitives; build a typed protocol adapter with exact only-in imports, define-type Key/Value/validate/serialization/equality slots, derived table/set/list capabilities, and generic contract tests")
  (emit "|selector role=typed-protocol-adapter symbol=RationalDict. selector=gerbil-poo://rationaldict.ss#RationalDict.")
  (emit "|selector role=derived-set-adapter symbol=RationalSet selector=gerbil-poo://rationaldict.ss#RationalSet")
  (emit "|selector role=table-protocol symbol=methods.table selector=gerbil-poo://table.ss#methods.table")
  (emit "|selector role=typed-validation-boundary symbol=.validate selector=gerbil-poo://rationaldict.ss#RationalDict..validate")
  (emit "|selector role=serialization-boundary symbol=.sexp<- selector=gerbil-poo://rationaldict.ss#RationalDict..sexp<-")
  (emit "|selector role=equality-boundary symbol=.=? selector=gerbil-poo://rationaldict.ss#RationalDict..=?")
  (emit "|selector role=protocol-derived-capability symbol=.join selector=gerbil-poo://table.ss#methods.table.join")
  (emit "|selector role=reusable-contract-test symbol=table-tests selector=gerbil-poo-test://t/table-testing.ss#table-tests")
  (emit "|selector role=io-serialization-method-family symbol=methods.bytes<-marshal selector=gerbil-poo://io.ss#methods.bytes<-marshal")
  (emit "|form role=typed-protocol-adapter symbol=RationalDict. head=define-type operands=(RationalDict. @ [methods.table] Value),Key: Rational,Value: Any keywords=.validate,.empty,.ref,.acons,.<-list,.list<-,.sexp<-,.=? selector=gerbil-poo://rationaldict.ss#RationalDict.")
  (emit "|form role=exact-dependency-import symbol=only-in head=only-in operands=:clan/pure/dict/rationaldict,rationaldict-put rationaldict-ref rationaldict->list list->rationaldict rationaldict=? keywords=precise-import-surface selector=gerbil-poo://rationaldict.ss#import:rationaldict")
  (emit "|form role=derived-set-adapter symbol=RationalSet head=define-type operands=(RationalSet @ [Set<-Table.]),Table: {(:: @T RationalDict.) Key: Elt Value: Unit} keywords=.list<-,.min-elt,.max-elt selector=gerbil-poo://rationaldict.ss#RationalSet")
  (emit "|form role=generic-contract-witness symbol=table-contract-tests head=table-contract-tests operands=<AdapterType>,<sample-key>,<sample-value> keywords=t/ owner,not line-number fixture selector=gerbil-poo-test://t/rationaldict-test.ss#rationaldict-test")
  (emit "|form role=minimal-protocol-surface symbol=methods.table head=define-type operands=Key,Value,.empty,.acons,.ref,.remove,.foldl,.foldr keywords=derive-secondary-capabilities selector=gerbil-poo://table.ss#methods.table")
  (emit "|form role=reusable-contract-test symbol=table-tests head=table-tests operands=<TypeDescriptor> keywords=small-t-owner,generic-contract selector=gerbil-poo-test://t/table-testing.ss#table-tests")
  (emit "|form role=serialization-method-family symbol=methods.bytes<-marshal head=define-type operands=.marshal,.unmarshal,.bytes<-,.<-bytes keywords=method-family-not-ad-hoc-functions selector=gerbil-poo://io.ss#methods.bytes<-marshal")
  (emit "|failureCase id=manual-hash-or-alist-adapter risk=dependency-boundary-bypass correction=follow-rationaldict-define-type-adapter-shape")
  (emit "|failureCase id=scattered-primitive-calls risk=adapter-boundary-missing correction=centralize-primitives-behind-define-type-slots")
  (emit "|failureCase id=line-number-contract-witness risk=fragile-test-witness correction=add-generic-table-or-protocol-contract-tests")
  (emit "|failureCase id=copied-monolithic-contract-suite risk=modularity-policy-violation correction=extract-reusable-contract-tests-into-small-t-owners")
  (emit "|qualitySignal id=dependency-backed-mapping")
  (emit "|qualitySignal id=rationaldict-source-example")
  (emit "|qualitySignal id=precise-only-in-import")
  (emit "|qualitySignal id=define-type-protocol-slots")
  (emit "|qualitySignal id=validation-serialization-equality-boundaries")
  (emit "|qualitySignal id=table-derived-set-capability")
  (emit "|qualitySignal id=generic-contract-witness-required")
  (emit "|qualitySignal id=minimal-protocol-surface")
  (emit "|qualitySignal id=reusable-contract-test")
  (emit "|qualitySignal id=serialization-method-family")
  (emit "|qualitySignal id=poo-prototype-object-extension")
  (emit "|quality verified missing=- selectorCount=9 formCount=7 failureCaseCount=4")
  (emit "next=search pattern poo rationaldict adapter"))

;; : (-> (List String) Integer )
(def (main . args)
  (let* ((raw-pattern-args
          (if (and (pair? args)
                   (equal? (car args) "pattern"))
            (cdr args)
            args))
         (terms (positional-args raw-pattern-args))
         (query (if (null? terms) "-" (string-join terms " ")))
         (pattern-focus (focus terms)))
    (if (has-term? terms "rationaldict")
      (emit-rationaldict-pattern query pattern-focus)
      (emit-object-system-pattern query pattern-focus))
    0))

(exit (apply main (entry-args)))
