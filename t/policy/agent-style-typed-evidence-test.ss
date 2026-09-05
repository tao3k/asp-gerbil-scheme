;;; -*- Gerbil -*-
;;; gerbil scheme harness agent style typed evidence policy.

(import :gerbil/gambit
        :std/test
        :std/misc/ports
        :std/misc/process
        :std/sort
        :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/policy/agent-style
        :asp-gerbil-scheme/src/policy/agent-style-performance-signals
        :asp-gerbil-scheme/src/policy/facade
        :asp-gerbil-scheme/src/policy/gxtest
        :asp-gerbil-scheme/src/scenario/policy
        :asp-gerbil-scheme/src/types/facade
        :unit/policy/poo-scenarios
        :policy/fixtures)
(import :policy/agent-style-support)
(export agent-style-typed-evidence-policy-test)

;; PolicyTest
(def agent-style-typed-evidence-policy-test
  (test-suite "gerbil scheme harness agent style typed evidence policy"
(test-case "typed-combinator-style policy rejects sparse implementation coverage"
          (let* ((root ".run/policy-typed-combinator-style-sparse-coverage")
                 (src (string-append root "/src"))
                 (owner (string-append src "/orders")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir src)
            (ensure-dir owner)
            (write-text (string-append root "/gerbil.pkg")
                        "(package: sample/orders)\n")
            (write-text (string-append owner "/core.ss")
                        ";;; -*- Gerbil -*-\n(package: sample/orders)\n;; : (-> Order Money)\n(def (order-total order) order)\n;; : (-> Order Tax)\n(def (order-tax order) order)\n;; : (-> (List Order) (List Money))\n(def (order-totals orders) (map order-total orders))\n;; : (-> Order Money)\n(def (order-net order) order)\n")
            (let* ((index (collect-project root))
                   (findings (run-policy-checks index))
                   (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-013" findings))
                   (finding (car matching))
                   (details (type-finding-details finding)))
              (check (length matching) => 1)
              (check (hash-get details 'missingImplementationEvidence) => #f)
              (check (hash-get details 'implementationCoverageInsufficient) => #t)
              (check (hash-get details 'functionDefinitionCount) => 4)
              (check (hash-get details 'coveredDefinitionCount) => 1)
              (check (hash-get details 'minimumCoveredDefinitionCount) => 3)
              (check (hash-get details 'uncoveredDefinitionCount) => 3)
              (check (agent-style-member?
                      "order-net"
                      (hash-get details 'uncoveredDefinitions))
                     => #t)
              (check (agent-style-member?
                      "expression-level-composition"
                      (hash-get details 'qualityFacets))
                     => #t)
              (check (agent-style-member?
                      "prefer map/filter/filter-map/fold pipelines; extract predicate, mapper, or reducer helpers before rewriting loops"
                      (hash-get details 'qualityFacetSteering))
                     => #t))))
(test-case "typed-combinator-style policy triggers on generic numeric hot loops"
          (let* ((root ".run/policy-typed-combinator-style-native-facets")
                 (src (string-append root "/src"))
                 (owner (string-append src "/orders")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir src)
            (ensure-dir owner)
            (write-text (string-append root "/gerbil.pkg")
                        "(package: sample/orders)\n")
            (write-text (string-append owner "/core.ss")
                        ";;; -*- Gerbil -*-\n(package: sample/orders)\n;; : (-> (List Number) Integer)\n(def (order-total xs)\n  (let loop ((rest xs) (acc 0))\n    (if (null? rest) acc (loop (cdr rest) (+ acc (car rest))))))\n")
            (let* ((index (collect-project root))
                   (findings (run-policy-checks index))
                   (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-013" findings))
                   (finding (car matching))
                   (details (type-finding-details finding))
                   (fact (car (project-typed-contract-facts index)))
                   (quality-facets (typed-contract-fact-quality-facets fact))
                   (repair-evidence (typed-contract-fact-repair-evidence fact)))
              (check (length matching) => 1)
              (check (type-finding-severity finding) => "warning")
              (check (hash-get details 'qualityRepairTriggered) => #t)
              (check (agent-style-member? "manual-loop-drift" quality-facets)
                     => #t)
              (check (agent-style-member? "combinator-candidate" quality-facets)
                     => #t)
              (check (agent-style-member?
                      "replace manual loops with map/filter/filter-map/fold pipelines when parser facts show no IO/state/generator witness"
                      (hash-get details 'qualityFacetSteering))
                     => #t)
              (check (agent-style-member?
                      "λ/lambda-match local destructuring"
                      (hash-get details 'gerbilUtilsImplementationSignals))
                     => #t)
              (check (agent-style-member?
                      "fun named lambda abstraction"
                      (hash-get details 'gerbilUtilsImplementationSignals))
                     => #t)
              (check (hash-get repair-evidence 'factSource) => "native-parser")
              (check (agent-style-member?
                      "replace-manual-loop-with-higher-order-combinator-when-no-state-witness"
                      (hash-get repair-evidence 'allowedMoves))
                     => #t))))
(test-case "numeric hot-loop evidence does not cross caller boundaries"
          (let* ((root ".run/policy-typed-combinator-style-numeric-caller-scope")
                 (src (string-append root "/src"))
                 (owner (string-append src "/orders")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir src)
            (ensure-dir owner)
            (write-text (string-append root "/gerbil.pkg")
                        "(package: sample/orders)\n")
            (write-text (string-append owner "/core.ss")
                        ";;; -*- Gerbil -*-\n(package: sample/orders)\n;; : (-> (List Number) Integer)\n(def (walk-orders xs)\n  (let loop ((rest xs))\n    (if (null? rest) 0 (loop (cdr rest)))))\n;; : (-> Number Number Number)\n(def (add-tax left right) (+ left right))\n;; : (-> Number Number Number)\n(def (remove-tax left right) (- left right))\n")
            (let* ((index (collect-project root))
                   (source (car (project-index-files index)))
                   (facets
                    (typed-combinator-style-upstream-performance-quality-facets
                     source)))
              (check (agent-style-member?
                      "generic-numeric-hot-loop"
                      facets)
                     => #f)
              (check (agent-style-member?
                      "numeric-domain-contract-missing"
                      facets)
                     => #f))))
(test-case "typed-combinator-style policy preserves Gambit primitive evidence without warning"
          (let* ((root ".run/policy-typed-combinator-style-gambit-hot-loop")
                 (src (string-append root "/src"))
                 (owner (string-append src "/orders")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir src)
            (ensure-dir owner)
            (write-text (string-append root "/gerbil.pkg")
                        "(package: sample/orders)\n")
            (write-text (string-append owner "/core.ss")
                        ";;; -*- Gerbil -*-\n(package: sample/orders)\n(import :gerbil/gambit)\n;; : (-> (List Flonum) Flonum)\n(def (sum-samples samples)\n  (let loop ((rest samples) (count 0) (total 0.0))\n    (if (null? rest)\n      total\n      (loop (cdr rest)\n            (fx+ count 1)\n            (fl+ total (car rest))))))\n")
            (let* ((index (collect-project root))
                   (findings (run-policy-checks index))
                   (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-013" findings)))
              (check matching => []))))
(test-case "typed-combinator-style policy triggers on reader collection loops"
          (let* ((root ".run/policy-typed-combinator-style-reader-collection")
                 (src (string-append root "/src"))
                 (owner (string-append src "/reader")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir src)
            (ensure-dir owner)
            (write-text (string-append root "/gerbil.pkg")
                        "(package: sample/reader)\n")
            (write-text (string-append owner "/core.ss")
                        ";;; -*- Gerbil -*-\n(package: sample/reader)\n;; : (-> Form (Maybe Symbol))\n(def (def-symbol form) (and (pair? form) (eq? (car form) 'def) (cadr form)))\n;; : (-> Path (List Symbol))\n(def (local-def-symbols file)\n  (call-with-input-file file\n    (lambda (port)\n      (let loop ((symbols []))\n        (let (form (read port))\n          (if (eof-object? form)\n            symbols\n            (let (symbol (def-symbol form))\n              (loop (if symbol (cons symbol symbols) symbols)))))))))\n")
            (let* ((index (collect-project root))
                   (findings (run-policy-checks index))
                   (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-013" findings))
                   (finding (car matching))
                   (details (type-finding-details finding)))
              (check (length matching) => 1)
              (check (agent-style-member?
                      "reader-collection-boundary"
                      (hash-get details 'qualityFacets))
                     => #t)
              (check (agent-style-member?
                      "source-form-reader-boundary"
                      (hash-get details 'qualityFacets))
                     => #t)
              (check (hash-get details 'loopDriverCombinatorTargets)
                     => ["local-def-symbols"])
              (check (agent-style-member?
                      "split source/form reader loops from selector or projection helpers, then compose the caller with filter-map/map/fold"
                      (hash-get details 'loopDriverCombinatorSignals))
                     => #t)
              (check (agent-style-member?
                      "when a reader loop also does selection or projection, split a source/form reader helper and compose the public function with filter-map/map/fold"
                      (hash-get details 'qualityFacetSteering))
                     => #t))))
(test-case "typed-combinator-style policy triggers on inline file reader loops"
          (let* ((root ".run/policy-typed-combinator-style-inline-file-reader")
                 (src (string-append root "/src"))
                 (owner (string-append src "/reader")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir src)
            (ensure-dir owner)
            (write-text (string-append root "/gerbil.pkg")
                        "(package: sample/reader)\n")
            (write-text (string-append owner "/core.ss")
                        ";;; -*- Gerbil -*-\n(package: sample/reader)\n;; : (-> Path (List Form))\n(def (source-forms file)\n  (call-with-input-file file\n    (lambda (port)\n      (let loop ((forms []))\n        (let (form (read port))\n          (if (eof-object? form)\n            (reverse forms)\n            (loop (cons form forms))))))))\n")
            (let* ((index (collect-project root))
                   (findings (run-policy-checks index))
                   (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-013" findings))
                   (finding (car matching))
                   (details (type-finding-details finding)))
              (check (length matching) => 1)
              (check (agent-style-member?
                      "inline-file-reader-boundary"
                      (hash-get details 'qualityFacets))
                     => #t)
              (check (agent-style-member?
                      "source-form-reader-boundary"
                      (hash-get details 'qualityFacets))
                     => #t)
              (check (hash-get details 'loopDriverCombinatorTargets)
                     => ["source-forms"])
              (check (agent-style-member?
                      "extract inline call-with-input-file reader loops into a port reader helper, then pass that helper to the file reader boundary"
                      (hash-get details 'loopDriverCombinatorSignals))
                     => #t)
              (check (agent-style-member?
                      "when a file helper opens a port and owns the EOF loop inline, extract a port reader helper and pass it directly to call-with-input-file"
                      (hash-get details 'qualityFacetSteering))
                     => #t))))
(test-case "typed-combinator-style exposes generator combinator steering"
          (let* ((root ".run/policy-typed-combinator-style-generator-steering")
                 (src (string-append root "/src"))
                 (owner (string-append src "/orders")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir src)
            (ensure-dir owner)
            (write-text (string-append root "/gerbil.pkg")
                        "(package: sample/orders)\n")
            (write-text (string-append owner "/core.ss")
                        ";;; -*- Gerbil -*-\n(package: sample/orders)\n;; : (-> (Generating Number) Number)\n(def (sum-generated source)\n  (let loop ((next source) (acc 0))\n    acc))\n")
            (let* ((index (collect-project root))
                   (findings (run-policy-checks index))
                   (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-013" findings))
                   (finding (car matching))
                   (details (type-finding-details finding)))
              (check (length matching) => 1)
              (check (agent-style-member?
                      "generator-combinator-boundary"
                      (hash-get details 'qualityFacets))
                     => #t)
              (check (agent-style-member?
                      "generating-fold reducer"
                      (hash-get details 'generatorCombinatorSignals))
                     => #t)
              (check (hash-get details 'generatorContractTargets)
                     => ["sum-generated"])
              (check (agent-style-member?
                      "when contracts mention Generating, prefer a named generator protocol boundary such as map, fold, partition, or merge style before hand-written producer loops; do not require a downstream gerbil-utils dependency"
                      (hash-get details 'qualityFacetSteering))
                     => #t))))
(test-case "typed-combinator-style exposes controlled macro syntax steering"
          (let* ((root ".run/policy-typed-combinator-style-controlled-macro-steering")
                 (src (string-append root "/src"))
                 (owner (string-append src "/macros")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir src)
            (ensure-dir owner)
            (write-text (string-append root "/gerbil.pkg")
                        "(package: sample/macros)\n")
            (write-text (string-append owner "/core.ss")
                        ";;; -*- Gerbil -*-\n(package: sample/macros)\n(defsyntax (with-order-field stx)\n  #'(void))\n")
            (let* ((index (collect-project root))
                   (findings (run-policy-checks index))
                   (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-013" findings))
                   (finding (car matching))
                   (details (type-finding-details finding)))
              (check (length matching) => 1)
              (check (agent-style-member?
                      "controlled-macro-syntax-boundary"
                      (hash-get details 'qualityFacets))
                     => #t)
              (check (agent-style-member?
                      "syntax-case/with-syntax transformer shape"
                      (hash-get details 'controlledMacroSyntaxSignals))
                     => #t)
              (check (agent-style-member?
                      "parameterize phase/context state instead of mutating global macro state"
                      (hash-get details 'controlledMacroSyntaxSignals))
                     => #t)
              (check (hash-get details 'controlledMacroTargets)
                     => ["with-order-field"]))))
(test-case "typed-combinator-style exposes POO typeclass algebra steering"
          (let* ((root ".run/policy-typed-combinator-style-typeclass-steering")
                 (src (string-append root "/src"))
                 (owner (string-append src "/orders")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir src)
            (ensure-dir owner)
            (write-text (string-append root "/gerbil.pkg")
                        "(package: sample/orders)\n")
            (write-text (string-append owner "/core.ss")
                        ";;; -*- Gerbil -*-\n(package: sample/orders)\n(import :clan/poo/object)\n(def (order-id value) value)\n(define-type (OrderFunctor. @ Functor.)\n  .map: map\n  .tap: tap\n  .ap: ap)\n")
            (let* ((index (collect-project root))
                   (findings (run-policy-checks index))
                   (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-013" findings))
                   (finding (car matching))
                   (details (type-finding-details finding)))
              (check (length matching) => 1)
              (check (agent-style-member?
                      "poo-typeclass-algebra-boundary"
                      (hash-get details 'qualityFacets))
                     => #t)
              (check (agent-style-member?
                      "Functor. map/tap/ap algebra"
                      (hash-get details 'typeclassAlgebraSignals))
                     => #t)
              (check (hash-get details 'typeclassAlgebraTargets)
                     => ["OrderFunctor."]))))
(test-case "typed-combinator-style routes method-table drift to compiler method pass reference"
          (let* ((root ".run/policy-typed-combinator-style-method-pass-reference")
                 (src (string-append root "/src"))
                 (owner (string-append src "/orders")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir src)
            (ensure-dir owner)
            (write-text (string-append root "/gerbil.pkg")
                        "(package: sample/orders)\n")
            (write-text (string-append owner "/core.ss")
                        ";;; -*- Gerbil -*-\n(package: sample/orders)\n(import :clan/poo/object)\n(def (order-id value) value)\n(define-type OrderProtocol.\n  .read: (lambda (self) self)\n  .write: (lambda (self value) value))\n")
            (let* ((index (collect-project root))
                   (findings (run-policy-checks index))
                   (matching (filter-rule "GERBIL-SCHEME-AGENT-POLICY-013" findings))
                   (finding (car matching))
                   (details (type-finding-details finding))
                   (quality-reference (hash-get details 'qualityReference)))
              (check (length matching) => 1)
              (check (agent-style-member?
                      "method-table-lambda-drift"
                      (hash-get details 'qualityFacets))
                     => #t)
              (check (hash-get quality-reference 'referencePattern)
                     => "gerbil-compiler-method-pass-boundary")
              (check (agent-style-member?
                      "gerbil://gerbil/compiler/method.ss#defcompile-method"
                      (hash-get quality-reference 'referenceExamples))
                     => #t)
              (check (agent-style-member?
                      "gerbil://gerbil/compiler/optimize-top.ss#dispatch-lambda-form?"
                      (hash-get quality-reference 'referenceExamples))
                     => #t)
              (check (agent-style-member?
                      "method-table-pass-boundary"
                      (hash-get quality-reference 'qualitySignals))
                     => #t)
              (check (agent-style-member?
                      "ast-case-shape-dispatch"
                      (hash-get quality-reference 'qualitySignals))
                     => #t)
              (check (agent-style-member?
                      "repair method-table lambdas by extracting slot-shaped helpers, compiler-style AST pass handlers, or cut/curry/compose adapters while preserving the receiver/protocol boundary"
                      (hash-get details 'qualityFacetSteering))
                     => #t))))
  ))
