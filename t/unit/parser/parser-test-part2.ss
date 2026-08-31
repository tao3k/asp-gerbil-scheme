;;; -*- Gerbil -*-
(import :std/test
        :asp-gerbil-scheme/src/extensions/facade
        :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/protocol/json
        :std/srfi/13)
(export parser-test-part-2)

;; : (-> Selector Relpath Boolean )
(def (selector-owner? selector path)
  (and (string? selector)
       (string-prefix? (string-append path ":") selector)))

;; : (-> (List CallFact) Argument FindCallWithArgument )
(def (find-call-with-argument calls argument)
  (find (lambda (call)
          (equal? (call-fact-arguments call) [argument]))
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
(def parser-test-part-2
  (test-suite "gerbil scheme harness parser part 2"
    (test-case "native reader captures complex Gerbil syntax facts"
          (let* ((root (path-normalize "."))
                 (file (parse-source-file root "t/fixtures/parser/complex-syntax.ss"))
                 (macros (source-file-macros file))
                 (with-widget-macro (find-macro macros "with-widget"))
                 (capture-safe-macro (find-macro macros "capture-safe")))
            (check (source-file-parse-error file) => #f)
            (check (map definition-name (source-file-definitions file))
                   => ["with-widget"
                       "capture-safe"
                       "<Widget>"
                       ":render"
                       "<Renderable>"
                       ":render"
                       "make-widget"
                       "dispatch"
                       "select"])
            (check (map module-import-fact-module (source-file-module-imports file))
                   => [":std/misc/path"
                       ":std/misc/repr"
                       ":std/misc/hash"
                       ":std/misc/list"
                       ":std/stxutil"
                       ":std/text/json"
                       ":std/sugar"])
            (check (map module-import-fact-modifier (source-file-module-imports file))
                   => ["for-template" "phi:" "except-in" "rename-in"
                       "for-syntax" "only-in" "direct"])
            (check (map module-import-fact-phase (source-file-module-imports file))
                   => ["template" "phase:1" "runtime" "runtime"
                       "syntax" "runtime" "runtime"])
            (check (map module-export-fact-name (source-file-module-exports file))
                   => [":render" "<Renderable>" "<Widget>" "with-widget" "make-widget"])
            (check (map module-export-fact-modifier (source-file-module-exports file))
                   => ["direct" "direct" "direct" "direct" "direct"])
            (check (map module-export-fact-symbols (source-file-module-exports file))
                   => [[":render"] ["<Renderable>"] ["<Widget>"] ["with-widget"] ["make-widget"]])
            (check (map macro-fact-name macros)
                   => ["with-widget" "capture-safe"])
            (check (map macro-fact-hygienic macros)
                   => [#t #t])
            (check (quality-facet-member? (macro-fact-quality-facets with-widget-macro)
                                          "hygienic-macro")
                   => #t)
            (check (quality-facet-member? (macro-fact-quality-facets with-widget-macro)
                                          "macro-sugar")
                   => #t)
            (check (quality-facet-member? (macro-fact-quality-facets capture-safe-macro)
                                          "syntax-case-transformer")
                   => #t)
            (check (quality-facet-member? (macro-fact-quality-facets capture-safe-macro)
                                          "syntax-template-witness")
                   => #t)
            (check (map poo-form-fact-role (source-file-poo-forms file))
                   => ["class" "generic" "protocol" "method"])
            (check (map poo-form-fact-generic (source-file-poo-forms file))
                   => (list #f ":render" #f ":render"))
            (check (map poo-form-fact-receiver (source-file-poo-forms file))
                   => (list #f #f #f "widget"))
            (check (map poo-form-fact-receiver-type (source-file-poo-forms file))
                   => (list #f #f #f "<Widget>"))
            (check (map poo-form-fact-supers (source-file-poo-forms file))
                   => (list [":object"] '() '() '()))
            (check (map poo-form-fact-slots (source-file-poo-forms file))
                   => (list ["name" "count"] '() '() '()))
            (check (map poo-form-fact-options (source-file-poo-forms file))
                   => (list ["transparent:"] '() '() '()))
            (check (map poo-form-fact-specializers (source-file-poo-forms file))
                   => (list '() '() '() ["widget:<Widget>"]))
            (check (map poo-form-fact-specializer-types (source-file-poo-forms file))
                   => (list '() '() '() ["<Widget>"]))
            (check (map binding-fact-kind (source-file-bindings file))
                   => ["macro-formal"
                       "macro-formal"
                       "macro-formal"
                       "let*"
                       "let*"
                       "let*"
                       "let"
                       "formal"
                       "formal"
                       "formal"
                       "formal"])
            (check (map call-fact-callee (source-file-calls file))
                   => [":render"
                       "open-input-string"
                       "read-json"
                       "displayln"
                       "make-<Widget>"
                       "with-widget"
                       "make-widget"
                       "make-widget"
                       "dispatch"
                       "make-widget"])
            (check (map (lambda (selector)
                          (selector-owner? selector "t/fixtures/parser/complex-syntax.ss"))
                        (map call-fact-selector (source-file-calls file)))
                   => [#t #t #t #t #t #t #t #t #t #t])))
    (test-case "native reader captures define-type POO facts"
          (let* ((root (path-normalize "."))
                 (file (parse-source-file root "t/fixtures/parser/poo-define-type.ss"))
                 (forms (source-file-poo-forms file))
                 (type-form (find-poo-form forms "RationalDict.")))
            (check (source-file-parse-error file) => #f)
            (check (map poo-form-fact-name forms) => ["RationalDict."])
            (check (poo-form-fact-kind type-form) => "define-type")
            (check (poo-form-fact-role type-form) => "type")
            (check (poo-form-fact-path type-form)
                   => "t/fixtures/parser/poo-define-type.ss")
            (check (poo-form-fact-supers type-form) => ["methods.table"])
            (check (not (not (member "Key:" (poo-form-fact-slots type-form))))
                   => #t)
            (check (not (not (member "Value:" (poo-form-fact-slots type-form))))
                   => #t)
            (check (not (not (member ".validate:" (poo-form-fact-slots type-form))))
                   => #t)
            (check (not (not (member "slots:" (poo-form-fact-options type-form))))
                   => #t)))
    (test-case "native reader captures finite-field POO descriptor facts"
          (let* ((root (path-normalize "."))
                 (file (parse-source-file root "t/fixtures/parser/poo-fq-descriptors.ss"))
                 (forms (source-file-poo-forms file))
                 (generic-field (find-poo-form forms "F_q."))
                 (binary-family (find-poo-form forms "F_2^n."))
                 (byte-field (find-poo-form forms "F_2^8")))
            (check (source-file-parse-error file) => #f)
            (check (map poo-form-fact-name forms) => ["F_q." "F_2^n." "F_2^8"])
            (check (map poo-form-fact-role forms) => ["type" "type" "type"])
            (check (poo-form-fact-supers generic-field) => ["expt<-mul-inv."])
            (check (not (not (member ".q:" (poo-form-fact-slots generic-field))))
                   => #t)
            (check (not (not (member ".mul:" (poo-form-fact-slots generic-field))))
                   => #t)
            (check (not (not (member ".n<-:" (poo-form-fact-slots generic-field))))
                   => #t)
            (check (not (not (member ".<-n:" (poo-form-fact-slots generic-field))))
                   => #t)
            (check (poo-form-fact-supers binary-family) => ["F_q."])
            (check (not (not (member ".p:" (poo-form-fact-slots binary-family))))
                   => #t)
            (check (not (not (member ".element?:" (poo-form-fact-slots binary-family))))
                   => #t)
            (check (not (not (member ".=?:"
                                      (poo-form-fact-slots binary-family))))
                   => #t)
            (check (poo-form-fact-supers byte-field) => ["F_2^n."])
            (check (poo-form-fact-slots byte-field) => [".n:" ".xn:"])))
    (test-case "native reader captures trie descriptor POO facts"
          (let* ((root (path-normalize "."))
                 (file (parse-source-file root "t/fixtures/parser/poo-trie-descriptor.ss"))
                 (forms (source-file-poo-forms file))
                 (trie (find-poo-form forms "Trie.")))
            (check (source-file-parse-error file) => #f)
            (check (map poo-form-fact-name forms) => ["Trie."])
            (check (poo-form-fact-role trie) => "type")
            (check (poo-form-fact-supers trie) => ["Wrap." "methods.table"])
            (check (not (not (member "Wrapper:" (poo-form-fact-slots trie))))
                   => #t)
            (check (not (not (member "Value:" (poo-form-fact-slots trie))))
                   => #t)
            (check (not (not (member "T:" (poo-form-fact-slots trie))))
                   => #t)
            (check (not (not (member "Unstep:" (poo-form-fact-slots trie))))
                   => #t)
            (check (not (not (member "Step:" (poo-form-fact-slots trie))))
                   => #t)
            (check (not (not (member ".acons:" (poo-form-fact-slots trie))))
                   => #t)
            (check (not (not (member ".<-list:" (poo-form-fact-slots trie))))
                   => #t)
            (check (not (not (member ".=?:"
                                      (poo-form-fact-slots trie))))
                   => #t)))))
