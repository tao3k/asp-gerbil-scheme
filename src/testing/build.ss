;;; -*- Gerbil -*-
;;; Thin downstream build.ss declaration facade over the POO testing framework.

(import :gerbil/gambit
        (only-in :std/sugar filter)
        :asp-gerbil-scheme/src/testing/model
        :asp-gerbil-scheme/src/testing/build-paths)

(export testing-build-path
        testing-build-contract-root
        testing-build-prefixed-import->file
        testing-build-default-import-prefix
        testing-build-import-prefix
        testing-build-import->file
        testing-build-gxtest-name
        testing-build-gxtest-root
        testing-build-basename
        testing-build-file-stem
        testing-build-gxtest-suite-symbol
        testing-build-trim-leading-dot-slash
        testing-build-datum-string
        testing-build-gxtest-module-symbol
        testing-build-gxtest-compiled-expression
        testing-build-replace-suffix
        testing-build-scenario-metadata
        testing-build-policy-scenario
        testing-build-policy-runner
        testing-build-gxtest-suite
        testing-build-policy-suite
        testing-build-filter
        testing-build-project
        testing-build
        testing-build-reset!
        testing-build-gxtest-runs
        testing-build-scenario-runs)

;; : (forall (A) (-> TestingBuild String (List (Pair Symbol A))))
;; testing-build-scenario-metadata
;; : (-> TestingBuild String Alist)
(def (testing-build-scenario-metadata build id)
  (let (entry (assoc id (testing-object-ref build 'scenarioMetadata [])))
    (if entry (cdr entry) [])))

;; : (-> TestingBuild String PolicyScenario)
(def (testing-build-policy-scenario build id)
  (list
   id
   (testing-build-path
    build
    (path-expand id (testing-object-ref build 'scenarioRoot "policy-scenarios")))
   (testing-build-scenario-metadata build id)))

;; : (-> TestingBuild Procedure)
(def (testing-build-policy-runner build)
  (lambda (scenario)
    (let (runs (testing-object-ref build 'scenarioRuns []))
      (vector-set! runs 0
                   (cons (car scenario)
                         (vector-ref runs 0))))
    scenario))

;; : (-> TestingBuild Datum GxTestSuite)
(def (testing-build-gxtest-suite build spec)
  (let* ((name (testing-build-gxtest-name spec))
         (root (testing-build-path build (testing-build-gxtest-root spec))))
    (testing-lazy-object
     'gxtest-suite
     `((name . ,name)
       (defaultRoot . ,root)
       (roots . ,(list root))
       (batchSize . ,(testing-object-ref build 'batchSize 2))
       (maxSelectedFiles . ,(testing-object-ref build 'maxSelectedFiles 2))
       (maxSelectedSources . ,(testing-object-ref build 'maxSelectedSources 4))
       (maxSelectedOutputs . ,(testing-object-ref build 'maxSelectedOutputs 4)))
     (lambda ()
       (let (contract-root (testing-build-contract-root build))
         (gxtest-suite
          name: name
          default-root: root
          roots: (list root)
          batch-size: (testing-object-ref build 'batchSize 2)
          import->file: (lambda (import)
                          (testing-build-import->file build import))
          max-selected-files: (testing-object-ref build 'maxSelectedFiles 2)
          max-selected-sources: (testing-object-ref build 'maxSelectedSources 4)
          max-selected-outputs: (testing-object-ref build 'maxSelectedOutputs 4)
          gates: (list
                  (performance-gate
                   name: (testing-object-ref build 'name "testing-build")
                   contract-root: contract-root))))))))

;; : (-> TestingBuild MaybeScenarioSuite)
(def (testing-build-policy-suite build)
  (let ((scenario-ids (testing-object-ref build 'scenarios [])))
    (and (not (null? scenario-ids))
         (scenario-suite
          name: (testing-object-ref build 'scenarioSuiteName "policy-scenarios")
          roots: (list
                  (testing-build-path
                   build
                   (testing-object-ref build 'scenarioRoot "policy-scenarios")))
          scenarios: (map (lambda (id)
                            (testing-build-policy-scenario build id))
                          scenario-ids)
          batch-size: 1
          runner: (testing-build-policy-runner build)
          gates: (list
                  (performance-gate
                   name: (testing-object-ref build 'name "testing-build")
                   contract-root: (testing-build-contract-root build)))))))

;; : (forall (A) (-> (List (Maybe A)) (List A)))
;; testing-build-filter
;; : (-> List List)
(def (testing-build-filter values)
  (filter identity values))

;; : (forall (A) (-> TestingBuild TestingProject))
;; testing-build-project
;; : (-> TestingBuild TestingProject)
(def (testing-build-project build)
  (let* ((gxtest-suites
          (map (lambda (spec)
                 (testing-build-gxtest-suite build spec))
               (testing-object-ref build 'gxtest [])))
         (performance-suites
          (testing-object-ref build 'performance []))
         (policy-suite (testing-build-policy-suite build))
         (project-roots
          (map (lambda (root)
                 (testing-build-path build root))
               (testing-object-ref build 'roots
                                   ["src" "t" "policy-scenarios"]))))
    (testing-project
     name: (testing-object-ref build 'name "testing-build")
     suites: (append gxtest-suites
                     performance-suites
                     (testing-build-filter (list policy-suite)))
     roots: project-roots
     batch-size: (testing-object-ref build 'batchSize 2)
     receipt-prefix: (testing-object-ref build 'receiptPrefix
                                         (testing-object-ref build 'name "testing-build")))))

;; : (-> String (Maybe String) Path (Maybe Path) (List Datum) (List PerformanceSuite) (List Path) (Maybe (List Path)) (List Path) (Maybe (List Path)) (Maybe Path) (List String) (Maybe (List String)) (List Alist) Path String (List Path) (Maybe String) Integer Integer Integer Integer Boolean (Maybe Path) Symbol Boolean (List Path) (Maybe String) TestingBuild)
(def (testing-build name: (name "testing-build")
                    package-name: (package-name #f)
                    root: (root ".")
                    contract-root: (contract-root #f)
                    gxtest: (gxtest [])
                    performance: (performance [])
                    support-files: (support-files [])
                    suite-support-files: (suite-support-files [])
                    support-directories: (support-directories [])
                    suite-support-directories: (suite-support-directories [])
                    support-output-root: (support-output-root #f)
                    scenarios: (scenarios [])
                    improvement-scenarios: (improvement-scenarios #f)
                    scenario-metadata: (scenario-metadata [])
                    scenario-root: (scenario-root "policy-scenarios")
                    scenario-suite-name: (scenario-suite-name "policy-scenarios")
                    roots: (roots ["src" "t" "policy-scenarios"])
                    import-prefix: (import-prefix #f)
                    batch-size: (batch-size 2)
                    max-selected-files: (max-selected-files 2)
                    max-selected-sources: (max-selected-sources 4)
                    max-selected-outputs: (max-selected-outputs 4)
                    policy: (policy #f)
                    loadpath: (loadpath #f)
                    output: (output 'summary)
                    compile-selected-tests: (compile-selected-tests #f)
                    compile-dependency-stamps: (compile-dependency-stamps [])
                    receipt-prefix: (receipt-prefix #f))
  (testing-object
   'testing-build
   `((name . ,name)
     (packageName . ,(or package-name name))
     (root . ,root)
     (contractRoot . ,(or contract-root root))
     (gxtest . ,gxtest)
     (performance . ,performance)
     (supportFiles . ,support-files)
     (suiteSupportFiles . ,suite-support-files)
     (supportDirectories . ,support-directories)
     (suiteSupportDirectories . ,suite-support-directories)
     (supportOutputRoot . ,support-output-root)
     (scenarios . ,(or improvement-scenarios scenarios))
     (scenarioMetadata . ,scenario-metadata)
     (scenarioRoot . ,scenario-root)
     (scenarioSuiteName . ,scenario-suite-name)
     (roots . ,roots)
     (importPrefix . ,import-prefix)
     (batchSize . ,batch-size)
     (maxSelectedFiles . ,max-selected-files)
     (maxSelectedSources . ,max-selected-sources)
     (maxSelectedOutputs . ,max-selected-outputs)
     (policy . ,policy)
     (loadpath . ,loadpath)
     (output . ,output)
     (compileSelectedTests . ,compile-selected-tests)
     (compileDependencyStamps . ,compile-dependency-stamps)
     (receiptPrefix . ,(or receipt-prefix name))
     (gxtestRuns . ,(vector []))
     (scenarioRuns . ,(vector [])))))

;; : (-> TestingBuild Unit)
(def (testing-build-reset! build)
  (vector-set! (testing-object-ref build 'gxtestRuns) 0 [])
  (vector-set! (testing-object-ref build 'scenarioRuns) 0 []))

;; : (forall (A) (-> TestingBuild (List A)))
(def (testing-build-gxtest-runs build)
  (reverse (vector-ref (testing-object-ref build 'gxtestRuns) 0)))

;; : (forall (A) (-> TestingBuild (List A)))
(def (testing-build-scenario-runs build)
  (reverse (vector-ref (testing-object-ref build 'scenarioRuns) 0)))
