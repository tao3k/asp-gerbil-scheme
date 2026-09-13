;;; -*- Gerbil -*-
;;; Query helpers over parser-owned project facts.

(import :asp-gerbil-scheme/src/parser/facade
        (only-in :std/sort sort)
        (only-in :std/srfi/1 append-map)
        (only-in :std/srfi/13
                 string-contains
                 string-downcase
                 string-empty?
                 string-join
                 string-tokenize))

(export matching-definitions
        ranked-files
        ranked-query-files)
;; matching-definitions
;;   : (-> (List Definition) (List String) (List Definition))
;;   | doc m%
;;       `matching-definitions definitions terms` keeps definitions whose names
;;       contain at least one query term, case-insensitively.
;;
;;       # Examples
;;
;;       ```scheme
;;       (matching-definitions definitions '("policy"))
;;       ;; => matching definitions
;;       ```
;;     %
(def (matching-definitions definitions terms)
  (if (null? terms)
    definitions
    (filter
     (lambda (defn)
       (ormap (lambda (term)
                (string-contains (string-downcase (definition-name defn))
                                 (string-downcase term)))
              terms))
     definitions)))
;; ranked-files
;;   : (-> ProjectIndex (List SourceFile))
;;   | doc m%
;;       `ranked-files index` returns source files ordered by descending
;;       definition count.
;;
;;       # Examples
;;
;;       ```scheme
;;       (map source-file-path (ranked-files index))
;;       ;; => owner paths
;;       ```
;;     %
(def (ranked-files index)
  (sort (project-index-files index)
        (lambda (a b)
          (> (length (source-file-definitions a))
             (length (source-file-definitions b))))))
;; ranked-query-files
;;   : (-> ProjectIndex String (List SourceFile))
;;   | doc m%
;;       `ranked-query-files index query` ranks source files by query score,
;;       then by definition count and stable owner path.
;;
;;       # Examples
;;
;;       ```scheme
;;       (ranked-query-files index "typed doc")
;;       ;; => ranked source files
;;       ```
;;     %
(def (ranked-query-files index query)
  (let* ((terms (query-terms query))
         (scored
          (filter-map
           (lambda (file)
             (let (score (source-file-query-score file terms))
               (and (> score 0) (cons file score))))
           (project-index-files index))))
    (map car
         (sort scored
               (lambda (left right)
                 (ranked-query-file>? (car left) (cdr left)
                                      (car right) (cdr right)))))))
;; : (-> Left LeftScore Right RightScore Boolean )
(def (ranked-query-file>? left left-score right right-score)
  (cond
   ((> left-score right-score) #t)
   ((< left-score right-score) #f)
   ((> (length (source-file-definitions left))
       (length (source-file-definitions right))) #t)
   ((< (length (source-file-definitions left))
       (length (source-file-definitions right))) #f)
   (else (string<? (source-file-path left) (source-file-path right)))))
;; source-file-query-score
;;   : (-> SourceFile (List String) Integer)
;;   | doc m%
;;       `source-file-query-score file terms` counts how many normalized terms
;;       are present in the file query haystack.
;;
;;       # Examples
;;
;;       ```scheme
;;       (source-file-query-score file '("macro" "policy"))
;;       ;; => 2
;;       ```
;;     %
(def (source-file-query-score file terms)
  (let (haystack (string-downcase (source-file-query-haystack file)))
    (length (filter (cut string-contains haystack <>)
                    terms))))
;; : (-> SourceFile SourceFileQueryHaystack )
(def (source-file-query-haystack file)
  (string-join (source-file-query-terms file) " "))
;; source-file-query-terms
;;   : (-> SourceFile (List String))
;;   | doc m%
;;       `source-file-query-terms file` returns searchable terms derived from a
;;       source file path, package metadata, imports, exports, and definitions.
;;
;;       # Examples
;;
;;       ```scheme
;;       (source-file-query-terms file)
;;       ;; => searchable terms
;;       ```
;;     %
(def (source-file-query-terms file)
  (filter searchable-term?
          (append
           [(source-file-path file)
            (source-file-package file)
            (source-file-prelude file)
            (source-file-namespace file)]
           (source-file-imports file)
           (source-file-exports file)
           (source-file-includes file)
           (append-map definition-query-terms
                       (source-file-definitions file))
           (append-map top-form-query-terms
                       (source-file-forms file))
           (append-map module-import-query-terms
                       (source-file-module-imports file))
           (append-map macro-query-terms
                       (source-file-macros file))
           (append-map binding-query-terms
                       (source-file-bindings file))
           (append-map poo-query-terms
                       (source-file-poo-forms file))
           (append-map higher-order-query-terms
                       (source-file-higher-order-forms file))
           (append-map control-flow-query-terms
                       (source-file-control-flow-forms file))
           (append-map dependency-adapter-quality-query-terms
                       (source-file-dependency-adapter-quality-facts file))
           (append-map call-query-terms
                       (source-file-calls file)))))
;; : (-> Definition Integer )
(def (definition-query-terms defn)
  [(definition-name defn)
   (definition-kind defn)
   (definition-selector defn)])
;; : (-> Form Integer )
(def (top-form-query-terms form)
  [(top-form-head form)
   (top-form-kind form)
   (top-form-selector form)])
;; : (-> String Integer )
(def (module-import-query-terms import)
  (append ["import" "module-import"
           (module-import-fact-module import)
           (module-import-fact-phase import)
           (module-import-fact-modifier import)
           (module-import-fact-alias import)
           (module-import-fact-selector import)]
          (module-import-fact-symbols import)))
;; : (-> Macro Integer )
(def (macro-query-terms macro)
  ["macro"
   (macro-fact-name macro)
   (macro-fact-kind macro)
   (macro-fact-transformer macro)
   (macro-fact-phase macro)
   (macro-fact-selector macro)])
;; : (-> Binding Integer )
(def (binding-query-terms binding)
  ["binding"
   (binding-fact-name binding)
   (binding-fact-kind binding)
   (binding-fact-scope binding)
   (binding-fact-value-type binding)
   (binding-fact-selector binding)])
;; : (-> PooFormFact (List SearchTerm) )
(def (poo-query-terms fact)
  (append ["poo"
           "object-system"
           (poo-form-fact-name fact)
           (poo-form-fact-kind fact)
           (poo-form-fact-role fact)
           (poo-form-fact-generic fact)
           (poo-form-fact-receiver fact)
           (poo-form-fact-receiver-type fact)
           (poo-form-fact-selector fact)]
          (poo-form-fact-supers fact)
          (poo-form-fact-slots fact)
          (poo-form-fact-options fact)
          (poo-form-fact-specializers fact)
          (poo-form-fact-specializer-types fact)))
;; : (-> HigherOrderFact (List SearchTerm) )
(def (higher-order-query-terms fact)
  ["higher-order"
   (higher-order-fact-name fact)
   (higher-order-fact-kind fact)
   (higher-order-fact-role fact)
   (higher-order-fact-caller fact)
   (higher-order-fact-selector fact)])
;; : (-> ControlFlowFact Integer )
(def (control-flow-query-terms fact)
  ["control-flow"
   (control-flow-fact-name fact)
   (control-flow-fact-kind fact)
   (control-flow-fact-role fact)
   (control-flow-fact-caller fact)
   (control-flow-fact-selector fact)])

;; : (-> DependencyAdapterQualityFact (List SearchTerm) )
(def (dependency-adapter-quality-query-terms fact)
  (append ["dependency-adapter-quality"
           "dependency-protocol-adapter"
           "adapter"
           "protocol-adapter"
           (dependency-adapter-quality-fact-name fact)
           (dependency-adapter-quality-fact-kind fact)
           (dependency-adapter-quality-fact-role fact)
           (dependency-adapter-quality-fact-dependency fact)
           (dependency-adapter-quality-fact-quality fact)
           (dependency-adapter-quality-fact-advice fact)
           (dependency-adapter-quality-fact-selector fact)]
          (dependency-adapter-quality-fact-imports fact)
          (dependency-adapter-quality-fact-imported-symbols fact)
          (dependency-adapter-quality-fact-used-symbols fact)
          (dependency-adapter-quality-fact-protocol-refs fact)
          (dependency-adapter-quality-fact-slots fact)
          (dependency-adapter-quality-fact-derived-capabilities fact)
          (dependency-adapter-quality-fact-quality-facets fact)
          (dependency-adapter-quality-fact-missing-evidence fact)
          [(dependency-adapter-quality-fact-manual-object-encoding-risk fact)
           (dependency-adapter-quality-fact-generic-contract-witness-kind fact)]))

;; call-query-terms
;;   : (-> CallFact (List String))
;;   | doc m%
;;       `call-query-terms call` returns searchable terms for a call fact,
;;       including callee, caller, selector, and argument types.
;;
;;       # Examples
;;
;;       ```scheme
;;       (call-query-terms call)
;;       ;; => call search terms
;;       ```
;;     %
(def (call-query-terms call)
  (append ["call"
           (call-fact-callee call)
           (call-fact-caller call)
           (call-fact-selector call)]
          (filter searchable-term? (call-fact-argument-types call))))
;; query-terms
;;   : (-> String (List String))
;;   | doc m%
;;       `query-terms query` tokenizes a query and returns searchable lowercase
;;       terms.
;;
;;       # Examples
;;
;;       ```scheme
;;       (query-terms "Typed Doc")
;;       ;; => ("typed" "doc")
;;       ```
;;     %
(def (query-terms query)
  (map string-downcase
       (filter searchable-term? (split-query query))))
;; split-query
;;   : (-> String (List String))
;;   | doc m%
;;       `split-query query` tokenizes a query string using Gerbil's string
;;       tokenizer.
;;
;;       # Examples
;;
;;       ```scheme
;;       (split-query "macro policy")
;;       ;; => ("macro" "policy")
;;       ```
;;     %
(def (split-query query)
  (string-tokenize query))
;; : (-> SearchTerm Boolean )
(def (searchable-term? value)
  (and value
       (string? value)
       (not (string-empty? value))))
