;;; -*- Gerbil -*-
(import :std/test
        :asp-gerbil-scheme/src/extensions/facade
        :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/protocol/json
        :std/srfi/13)
(export parser-test-part-4)

;; : (-> Selector Relpath Boolean )
(def (selector-owner? selector path)
  (and (string? selector)
       (string-prefix? (string-append path ":") selector)))

;; : (-> (List CallFact) Argument FindCallWithArgument )
(def (find-call-with-argument calls argument)
  (find (lambda (call)
          (equal? (call-fact-arguments call) [argument]))
        calls))
;; : (-> (List CallFact) Callee FindCallByCallee )
(def (find-call-by-callee calls callee)
  (find (lambda (call)
          (equal? (call-fact-callee call) callee))
        calls))
;; : (-> (List QualityFacet) QualityFacet Boolean )
(def (quality-facet-member? facets facet)
  (not (not (member facet facets))))
;; : (-> (List MacroFact) String MacroFact )
(def (find-macro facts name)
  (find (lambda (fact)
          (equal? (macro-fact-name fact) name))
        facts))
;; : (-> (List HigherOrderFact) String String String (List HigherOrderFact) )
(def (find-higher-order facts name role caller)
  (find (lambda (fact)
          (and (equal? (higher-order-fact-name fact) name)
               (equal? (higher-order-fact-role fact) role)
               (equal? (or (higher-order-fact-caller fact) "") caller)))
        facts))
;; : (-> (List ControlFlowFact) String String String (List ControlFlowFact) )
(def (find-control-flow facts name role caller)
  (find (lambda (fact)
          (and (equal? (control-flow-fact-name fact) name)
               (equal? (control-flow-fact-role fact) role)
               (equal? (or (control-flow-fact-caller fact) "") caller)))
        facts))
;; : (-> (List TypedContractFact) String (List TypedContractFact) )
(def (find-typed-contract facts name)
  (find (lambda (fact)
          (equal? (typed-contract-fact-definition-name fact) name))
        facts))
;; : (-> (List PredicateFamilyFact) String PredicateFamilyFact )
(def (find-predicate-family facts subject)
  (find (lambda (fact)
          (equal? (predicate-family-fact-subject fact) subject))
        facts))
;; : (-> (List FieldAccessPatternFact) String FieldAccessPatternFact )
(def (find-field-access-pattern facts field-key)
  (find (lambda (fact)
          (equal? (field-access-pattern-fact-field-key fact) field-key))
        facts))
;; : (-> (List BooleanConditionFact) String BooleanConditionFact )
(def (find-boolean-condition facts caller)
  (find (lambda (fact)
          (equal? (boolean-condition-fact-caller fact) caller))
        facts))
;; : (-> (List LoopDriverFact) String LoopDriverFact )
(def (find-loop-driver facts caller)
  (find (lambda (fact)
          (equal? (loop-driver-fact-caller fact) caller))
        facts))
;; : (-> (List FunctionQualityProfile) String FunctionQualityProfile )
(def (find-function-quality-profile profiles name)
  (find (lambda (profile)
          (equal? (function-quality-profile-name profile) name))
        profiles))
;; : (-> (List PooFormFact) String PooFormFact )
(def (find-poo-form facts name)
  (find (lambda (fact)
          (equal? (poo-form-fact-name fact) name))
        facts))
;; : (-> (List PooFormFact) String String PooFormFact )
(def (find-poo-form-role facts name role)
  (find (lambda (fact)
          (and (equal? (poo-form-fact-name fact) name)
               (equal? (poo-form-fact-role fact) role)))
        facts))
;; ParsedData
;; : (-> String EnsureDir )
(def (ensure-dir path)
  (with-catch
   (lambda (_) #f)
   (lambda () (create-directory path))))
;; : (-> String SourceLine Unit )
(def (write-text path text)
  (with-catch
   (lambda (_) #f)
   (lambda () (delete-file path)))
  (call-with-output-file path
    (lambda (port) (display text port))))
;; TestSuite
(def parser-test-part-4
  (test-suite "gerbil scheme harness parser part 4"
    (test-case "native reader captures defgeneric POO option facts"
          (let* ((root (path-normalize "."))
                 (file (parse-source-file root "t/fixtures/parser/poo-defgeneric.ss"))
                 (forms (source-file-poo-forms file))
                 (location (find-poo-form forms "location"))
                 (factory (find-poo-form forms "factory")))
            (check (source-file-parse-error file) => #f)
            (check (map poo-form-fact-name forms) => ["location" "factory"])
            (check (map poo-form-fact-role forms) => ["generic" "generic"])
            (check (poo-form-fact-generic location) => "location")
            (check (poo-form-fact-options location)
                   => ["slot:location" "slotName:location"
                       "from:type" "dispatchSource:type"
                       "default:" "defaultStrategy:default"])
            (check (poo-form-fact-generic factory) => "factory")
            (check (poo-form-fact-options factory)
                   => ["compute-default:" "defaultStrategy:computed"
                       "dispatchSource:instance"])))
    (test-case "native reader classifies POO object slot syntax"
          (let* ((root (path-normalize "."))
                 (file (parse-source-file root "t/fixtures/parser/poo-object-slots.ss"))
                 (forms (source-file-poo-forms file))
                 (point (find-poo-form forms "point")))
            (check (source-file-parse-error file) => #f)
            (check (map poo-form-fact-name forms) => ["base" "point"])
            (check (poo-form-fact-role point) => "object")
            (check (poo-form-fact-supers point) => ["base"])
            (check (poo-form-fact-slots point)
                   => ["x" "y" "total" "level" "child" "label" "greeting"])
            (check (poo-form-fact-options point)
                   => ["slot:x:lexical-constant"
                       "slot:y:self-computed"
                       "slot:total:self-computed"
                       "slot:level:inherited-computed"
                       "slot:child:mixin-override"
                       "slot:label:default"
                       "slot:greeting:inherited-computed"])))
    (test-case "native reader captures POO slot-cache inheritance witness"
          (let* ((root (path-normalize "."))
                 (file (parse-source-file root "t/fixtures/parser/poo-slot-cache-inheritance.ss"))
                 (forms (source-file-poo-forms file))
                 (cache-node (find-poo-form forms "cache-node"))
                 (calls (source-file-calls file))
                 (ref-call (find-call-by-callee calls ".ref"))
                 (ref-cached-call (find-call-by-callee calls ".ref/cached"))
                 (apply-slot-spec-call (find-call-by-callee calls "apply-slot-spec")))
            (check (source-file-parse-error file) => #f)
            (check (map poo-form-fact-name forms)
                   => ["root-cache" "left-cache" "right-cache" "cache-node"])
            (check (poo-form-fact-supers cache-node)
                   => ["left-cache" "right-cache"])
            (check (poo-form-fact-slots cache-node)
                   => ["stable" "inherited-count" "cached-child"
                       "super-label" "local-cache"])
            (check (poo-form-fact-options cache-node)
                   => ["slot:stable:default"
                       "slot:inherited-count:inherited-computed"
                       "slot:cached-child:mixin-override"
                       "slot:super-label:inherited-computed"
                       "slot:local-cache:self-computed"])
            (check (not
                    (not
                     (and (member ".o" (map call-fact-callee calls))
                          (member "compute-cache" (map call-fact-callee calls))
                          (member "next-method" (map call-fact-callee calls))
                          (member "super-label" (map call-fact-callee calls))
                          (member ".ref" (map call-fact-callee calls))
                          (member ".ref/cached" (map call-fact-callee calls))
                          (member "apply-slot-spec" (map call-fact-callee calls)))))
                   => #t)
            (check (call-fact-caller ref-call) => "slot-cache-boundary")
            (check (call-fact-caller ref-cached-call) => "slot-cache-boundary")
            (check (call-fact-caller apply-slot-spec-call) => "slot-cache-boundary")))
    (test-case "JSON projection exposes POO object slot syntax facts"
          (let* ((root (path-normalize "."))
                 (file (parse-source-file root "t/fixtures/parser/poo-object-slots.ss"))
                 (packet (source-file-json file))
                 (forms (hash-get packet 'pooForms))
                 (point (find (lambda (form)
                                (equal? (hash-get form 'name) "point"))
                              forms)))
            (check (hash-get point 'role) => "object")
            (check (hash-get point 'supers) => ["base"])
            (check (hash-get point 'slots)
                   => ["x" "y" "total" "level" "child" "label" "greeting"])
            (check (hash-get point 'options)
                   => ["slot:x:lexical-constant"
                       "slot:y:self-computed"
                       "slot:total:self-computed"
                       "slot:level:inherited-computed"
                       "slot:child:mixin-override"
                       "slot:label:default"
                       "slot:greeting:inherited-computed"])))
    (test-case "native reader captures runtime module sugar definitions"
          (let* ((root (path-normalize "."))
                 (file (parse-source-file root "t/fixtures/parser/runtime-module-sugar.ss"))
                 (macros (source-file-macros file))
                 (only-in (find-macro macros "only-in"))
                 (except-out (find-macro macros "except-out"))
                 (for-syntax (find-macro macros "for-syntax")))
            (check (source-file-parse-error file) => #f)
            (check (source-file-prelude file) => ":<root>")
            (check (source-file-package file) => "sample/runtime-module-sugar")
            (check (map definition-name (source-file-definitions file))
                   => ["only-in" "except-out" "for-syntax"])
            (check (map definition-kind (source-file-definitions file))
                   => ["defsyntax-for-import"
                       "defsyntax-for-export"
                       "defsyntax-for-import-export"])
            (check (map definition-formals (source-file-definitions file))
                   => [["stx"] ["stx"] ["stx"]])
            (check (map macro-fact-phase macros)
                   => ["import" "export" "import-export"])
            (check (macro-fact-kind only-in) => "defsyntax-for-import")
            (check (macro-fact-kind except-out) => "defsyntax-for-export")
            (check (macro-fact-kind for-syntax) => "defsyntax-for-import-export")
            (check (quality-facet-member? (macro-fact-quality-facets only-in)
                                          "syntax-case-transformer")
                   => #t)
            (check (quality-facet-member? (macro-fact-quality-facets only-in)
                                          "syntax-object-validation")
                   => #t)
            (check (quality-facet-member? (macro-fact-quality-facets only-in)
                                          "phase-specific-macro")
                   => #t)
            (check (quality-facet-member? (macro-fact-quality-facets only-in)
                                          "phase-extension-hook")
                   => #t)))
    (test-case "native reader captures syntax parameter macro context facts"
          (let* ((root (path-normalize "."))
                 (file
                  (parse-source-file
                   root
                   "t/scenarios/policy/syntax-parameterized-context-boundary/expected/src/macros/context.ss"))
                 (macros (source-file-macros file))
                 (flow-param (find-macro macros "@flow"))
                 (with-flow-context (find-macro macros "with-flow-context")))
            (check (source-file-parse-error file) => #f)
            (check (macro-fact-kind flow-param) => "defsyntax-parameter*")
            (check (quality-facet-member?
                    (macro-fact-quality-facets flow-param)
                    "syntax-parameter-definition")
                   => #t)
            (check (quality-facet-member?
                    (macro-fact-quality-facets with-flow-context)
                    "syntax-parameterized-context")
                   => #t)
            (check (quality-facet-member?
                    (macro-fact-quality-facets with-flow-context)
                    "syntax-object-validation")
                   => #t)
            (check (quality-facet-member?
                    (macro-fact-quality-facets with-flow-context)
                    "source-aware-syntax-error")
                   => #t)))
    (test-case "native reader captures manual syntax registry macro facts"
          (let* ((root (path-normalize "."))
                 (file
                  (parse-source-file
                   root
                   "t/scenarios/policy/syntax-local-registry-boundary/input/src/macros/registry.ss"))
                 (macros (source-file-macros file))
                 (def-flow-type (find-macro macros "def-flow-type")))
            (check (source-file-parse-error file) => #f)
            (check (quality-facet-member?
                    (macro-fact-quality-facets def-flow-type)
                    "manual-syntax-registry-table")
                   => #t)
            (check (quality-facet-member?
                    (macro-fact-quality-facets def-flow-type)
                    "syntax-datum-registry-key")
                   => #t)))))
