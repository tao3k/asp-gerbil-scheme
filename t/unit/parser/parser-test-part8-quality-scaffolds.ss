;;; -*- Gerbil -*-
;;; gerbil scheme harness parser part 8 quality scaffolds.

(import :std/test
        :asp-gerbil-scheme/src/extensions/facade
        :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/parser/typed-contract-scheme
        :asp-gerbil-scheme/src/protocol/json
        :asp-gerbil-scheme/src/protocol/structural-facts
        :std/srfi/13)
(import :unit/parser/parser-test-part8-support)
(export parser-test-part-8-quality-scaffolds)

;; PolicyTest
(def parser-test-part-8-quality-scaffolds
  (test-suite "gerbil scheme harness parser part 8 quality scaffolds"
(test-case "parser exposes boolean normalization scaffold facts"
          (let* ((root (path-normalize ".run/parser-boolean-normalization"))
                 (source-dir (string-append root "/src"))
                 (package-path (string-append root "/gerbil.pkg"))
                 (source-path (string-append source-dir "/core.ss")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir source-dir)
            (write-text package-path "(package: sample/boolean-normalization)\n")
            (write-text
             source-path
             ";;; -*- Gerbil -*-\n\
(package: sample/boolean-normalization)\n\
;; : (-> (List Symbol) Boolean)\n\
(def (selected? choices)\n\
  (not (not (member 'ready choices))))\n")
            (let* ((file (parse-source-file root "src/core.ss"))
                   (fact
                    (find (lambda (item)
                            (equal? (boolean-condition-fact-role item)
                                    "boolean-normalization-scaffold"))
                          (source-file-boolean-condition-facts file))))
              (check (not fact) => #f)
              (check (boolean-condition-fact-caller fact) => "selected?")
              (check (quality-facet-member?
                      (boolean-condition-fact-quality-facets fact)
                      "boolean-normalization-drift")
                     => #t)
              (check (quality-facet-member?
                      (boolean-condition-fact-quality-facets fact)
                      "generated-scaffold-shape")
                     => #t))))
(test-case "parser keeps boolean normalization AST-owned"
          (let* ((root (path-normalize ".run/parser-boolean-normalization-ast"))
                 (source-dir (string-append root "/src"))
                 (package-path (string-append root "/gerbil.pkg"))
                 (source-path (string-append source-dir "/core.ss")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir source-dir)
            (write-text package-path "(package: sample/boolean-normalization-ast)\n")
            (write-text
             source-path
             ";;; -*- Gerbil -*-\n\
(package: sample/boolean-normalization-ast)\n\
;; : (-> Boolean Boolean Boolean)\n\
(def (mixed? left right)\n\
  (not (or left (not right))))\n\
;; : (-> Symbol Symbol)\n\
(def (quoted-shape value)\n\
  '(not (not value)))\n")
            (let* ((file (parse-source-file root "src/core.ss"))
                   (facts
                    (filter (lambda (item)
                              (equal? (boolean-condition-fact-role item)
                                      "boolean-normalization-scaffold"))
                            (source-file-boolean-condition-facts file))))
              (check facts => []))))
(test-case "parser exposes inline alist lookup as AST-owned field access"
          (let* ((root (path-normalize ".run/parser-inline-alist-access"))
                 (source-dir (string-append root "/src"))
                 (package-path (string-append root "/gerbil.pkg"))
                 (source-path (string-append source-dir "/core.ss")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir source-dir)
            (write-text package-path "(package: sample/inline-alist)\n")
            (write-text
             source-path
             ";;; -*- Gerbil -*-\n\
(package: sample/inline-alist)\n\
;; : (-> Profile Value)\n\
(def (profile-name profile)\n\
  (cdr (assq 'name profile)))\n\
;; : (-> Profile Value)\n\
(def (profile-owner profile)\n\
  (cdr (assq 'owner profile)))\n\
;; : (-> Value Value)\n\
(def (quoted-shape value)\n\
  '(cdr (assq 'name profile)))\n")
            (let* ((file (parse-source-file root "src/core.ss"))
                   (facts (source-file-field-access-pattern-facts file))
                   (name-fact (find-field-access-pattern facts "alist:name"))
                   (owner-fact (find-field-access-pattern facts "alist:owner")))
              (check (not name-fact) => #f)
              (check (field-access-pattern-fact-role name-fact)
                     => "inline-alist-lookup")
              (check (field-access-pattern-fact-callers name-fact)
                     => ["profile-name"])
              (check (field-access-pattern-fact-access-count name-fact) => 1)
              (check (quality-facet-member?
                      (field-access-pattern-fact-quality-facets name-fact)
                      "inline-alist-lookup-drift")
                     => #t)
              (check (not owner-fact) => #f)
              (check (field-access-pattern-fact-callers owner-fact)
                     => ["profile-owner"]))))
(test-case "parser exposes poo method bodies and gerbil-utils fun helpers"
          (let* ((root (path-normalize ".run/parser-poo-method-fun"))
                 (source-dir (string-append root "/src"))
                 (package-path (string-append root "/gerbil.pkg"))
                 (source-path (string-append source-dir "/core.ss")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir source-dir)
            (write-text package-path "(package: sample/poo-method-fun)\n")
            (write-text
             source-path
             ";;; -*- Gerbil -*-\n\
(package: sample/poo-method-fun/core)\n\
;; Integer\n\
(define-type (Box @ [Wrapper.] T .wrap .unwrap)\n\
  .map: (lambda (f x) (.wrap (f (.unwrap x))))\n\
  .unwrap*: (cut .unwrap <>)\n\
  .wrap*: .wrap\n\
  .empty: []\n\
  .validate: (lambda (super) (lambda (value) (super value))))\n\
;; : (-> (List String) (List String) )\n\
(def (label-items items)\n\
  (map (fun (label-item item)\n\
         (string-append \"item:\" item))\n\
       items))\n")
            (let* ((file (parse-source-file root "src/core.ss"))
                 (box (find-poo-form (source-file-poo-forms file) "Box"))
                 (box-profile
                  (find-function-quality-profile
                   (source-file-function-quality-profiles file)
                   "Box"))
                 (fun-fact
                  (find-higher-order
                   (source-file-higher-order-forms file)
                   "fun"
                   "named-lambda-abstraction"
                   "label-items"))
                 (map-fact
                  (find-higher-order
                   (source-file-higher-order-forms file)
                   "map"
                   "sequence-map"
                   "label-items")))
            (check (not (not box)) => #t)
            (check (not (not (member ".wrap" (poo-form-fact-slots box))))
                   => #t)
            (check (not (not (member ".unwrap" (poo-form-fact-slots box))))
                   => #t)
            (check (not (not (member ".map" (poo-form-fact-slots box))))
                   => #t)
            (check (not (not (member ".unwrap*" (poo-form-fact-slots box))))
                   => #t)
            (check (not (not (member "methodSlot:.map"
                                     (poo-form-fact-options box))))
                   => #t)
            (check (not (not (member "methodBody:.map:lambda"
                                     (poo-form-fact-options box))))
                   => #t)
            (check (not (not (member "methodBodyQuality:.map:lambda-drift"
                                     (poo-form-fact-options box))))
                   => #t)
            (check (not (not (member "methodTableBody:lambda-drift"
                                     (poo-form-fact-options box))))
                   => #t)
            (check (not (not (member "methodBody:.unwrap*:partial-application"
                                     (poo-form-fact-options box))))
                   => #t)
            (check (not (not (member "methodBodyQuality:.unwrap*:combinator"
                                     (poo-form-fact-options box))))
                   => #t)
            (check (not (not (member "methodTableBody:combinator"
                                     (poo-form-fact-options box))))
                   => #t)
            (check (not (not (member "methodBody:.wrap*:identifier"
                                     (poo-form-fact-options box))))
                   => #t)
            (check (not (not (member "methodBody:.empty:call:@list"
                                     (poo-form-fact-options box))))
                   => #t)
            (check (member "methodBodyQuality:.empty:low-level"
                           (poo-form-fact-options box))
                   => #f)
            (check (not (not (member "methodBodyQuality:.validate:validation-boundary"
                                     (poo-form-fact-options box))))
                   => #t)
            (check (member "methodBodyQuality:.validate:lambda-drift"
                           (poo-form-fact-options box))
                   => #f)
            (check (not box-profile) => #f)
            (check (quality-facet-member?
                    (function-quality-profile-quality-facets box-profile)
                    "method-table-lambda-drift")
                   => #t)
            (check (quality-facet-member?
                    (function-quality-profile-quality-facets box-profile)
                    "method-table-validation-boundary")
                   => #t)
            (check (quality-facet-member?
                    (function-quality-profile-quality-facets box-profile)
                    "method-table-combinator-body")
                   => #t)
            (check (function-quality-profile-suggested-repair-class
                    box-profile)
                   => "poo-policy")
            (check (not (not fun-fact)) => #t)
            (check (higher-order-fact-operand-count fun-fact) => 2)
            (check (not (not (member "named-lambda-helper"
                                     (higher-order-quality-facets fun-fact))))
                   => #t)
            (check (not (not map-fact)) => #t)
            (check (not (not (member "expression-level-composition"
                                     (higher-order-quality-facets map-fact))))
                   => #t))))
(test-case "parser distinguishes reader collection loops from pure reader boundaries"
          (let* ((root (path-normalize ".run/parser-reader-collection-boundary"))
                 (source-dir (string-append root "/src"))
                 (package-path (string-append root "/gerbil.pkg"))
                 (source-path (string-append source-dir "/core.ss")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir source-dir)
            (write-text package-path "(package: sample/reader-collection)\n")
            (write-text
             source-path
             ";;; -*- Gerbil -*-\n\
(package: sample/reader-collection)\n\
;; : (-> Form (Maybe Symbol))\n\
(def (def-symbol form)\n\
  (and (pair? form) (eq? (car form) 'def) (cadr form)))\n\
;; : (-> Path (List Form))\n\
(def (read-forms port)\n\
  (let loop ((forms []))\n\
    (let (form (read port))\n\
      (if (eof-object? form)\n\
        (reverse forms)\n\
        (loop (cons form forms))))))\n\
;; : (-> Path (List Form))\n\
(def (source-forms file)\n\
  (call-with-input-file file\n\
    (lambda (port)\n\
      (let loop ((forms []))\n\
        (let (form (read port))\n\
          (if (eof-object? form)\n\
            (reverse forms)\n\
            (loop (cons form forms))))))))\n\
;; : (-> Path (List Symbol))\n\
(def (local-def-symbols file)\n\
  (call-with-input-file file\n\
    (lambda (port)\n\
      (let loop ((symbols []))\n\
        (let (form (read port))\n\
          (if (eof-object? form)\n\
            symbols\n\
            (let (symbol (def-symbol form))\n\
              (loop (if symbol (cons symbol symbols) symbols)))))))))\n")
            (let* ((file (parse-source-file root "src/core.ss"))
                   (reader-facts (source-file-loop-driver-facts file))
                   (read-forms-fact
                    (find (lambda (fact)
                            (equal? (loop-driver-fact-caller fact)
                                    "read-forms"))
                          reader-facts))
                   (source-forms-fact
                    (find (lambda (fact)
                            (equal? (loop-driver-fact-caller fact)
                                    "source-forms"))
                          reader-facts))
                   (local-defs-fact
                    (find (lambda (fact)
                            (equal? (loop-driver-fact-caller fact)
                                    "local-def-symbols"))
                          reader-facts))
                   (local-profile
                    (find-function-quality-profile
                     (source-file-function-quality-profiles file)
                     "local-def-symbols")))
              (check (not read-forms-fact) => #f)
              (check (loop-driver-fact-driver-kind read-forms-fact)
                     => "io-reader-driver")
              (check (quality-facet-member?
                      (loop-driver-fact-quality-facets read-forms-fact)
                      "io-state-boundary")
                     => #t)
              (check (not source-forms-fact) => #f)
              (check (loop-driver-fact-driver-kind source-forms-fact)
                     => "inline-file-reader-candidate")
              (check (quality-facet-member?
                      (loop-driver-fact-quality-facets source-forms-fact)
                      "inline-file-reader-boundary")
                     => #t)
              (check (quality-facet-member?
                      (loop-driver-fact-quality-facets source-forms-fact)
                      "source-form-reader-boundary")
                     => #t)
              (check (not local-defs-fact) => #f)
              (check (loop-driver-fact-driver-kind local-defs-fact)
                     => "reader-collection-candidate")
              (check (quality-facet-member?
                      (loop-driver-fact-quality-facets local-defs-fact)
                      "reader-collection-boundary")
                     => #t)
              (check (quality-facet-member?
                      (function-quality-profile-quality-facets local-profile)
                      "manual-loop-drift")
                     => #t)
              (check (quality-facet-member?
                      (function-quality-profile-quality-facets local-profile)
                      "source-form-reader-boundary")
                     => #t)
              (check (function-quality-profile-suggested-repair-class
                      local-profile)
                     => "typed-combinator-style"))))
  ))
