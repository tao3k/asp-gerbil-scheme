;;; -*- Gerbil -*-
;;; Boundary:
;;; - test owner records policy expectations.
;;; - Keep typed contracts and fixture intent explicit.
(import :asp-gerbil-scheme/src/extensions/facade
        :asp-gerbil-scheme/src/extensions/poo-patterns
        :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/snapshot/facade
        :std/test
        (only-in :std/sugar andmap)
        (only-in :std/srfi/13 string-join))
(export extensions-test)
;; : TestSuite
(def extensions-test
  (test-suite "gerbil scheme harness extensions"
    (test-case "poo extension packet matches snapshot"
      (let* ((root ".run/extensions-poo-required")
             (_ (write-extension-project
                 root
                 "sample/app"
                 ["git.cons.io/mighty-gerbils/gerbil-poo"]))
             (index (collect-project root))
             (snapshot (extension-packet-snapshot index))
             (expected (snapshot-load "t/snapshots/poo-extension-packet.ss")))
        (check snapshot => expected)))
    (test-case "poo pattern specs are static POO objects"
      (check (poo-pattern-id 'object-system) => "poo-object-system")
      (check (poo-pattern-id 'prototype-composition)
             => "poo-prototype-composition")
      (check (poo-pattern-agent-steering 'prototype-composition)
             => "follow the emitted selectors and minimal forms before writing Gerbil POO code; avoid Racket class or generic Scheme object guesses"))
    (test-case "poo dependency aliases activate extension"
      (let* ((root ".run/extensions-poo-alias")
             (_ (write-extension-project root "sample/app" ["clan/poo"]))
             (index (collect-project root))
             (extension (car (project-extension-json index)))
             (source-ref (poo-source-ref index)))
        (check (poo-extension-active? index) => #t)
        (check (hash-get extension 'name) => "poo")
        (check (hash-get extension 'dependencyMode) => "required")
        (check (hash-get extension 'dependencies) => ["clan/poo"])
        (check (hash-get source-ref 'kind) => "package-manager-source")
        (check (hash-get source-ref 'manager) => "gxpkg")
        (check (hash-get source-ref 'dependency) => "clan/poo")
        (check (hash-get (hash-get source-ref 'localSource) 'rootHint)
               => "~/.gerbil")
        (check (hash-get (hash-get source-ref 'localSource) 'status)
               => "probe-first")
        (check (hash-get (hash-get source-ref 'localSource) 'missingAction)
               => "install-package-before-repository-fallback")
        (check (hash-get (hash-get source-ref 'localSource) 'installHint)
               => "gxpkg install clan/poo")
        (check (hash-get (hash-get source-ref 'repositorySource) 'url)
               => "https://git.cons.io/mighty-gerbils/gerbil-poo")
        (check (hash-get (hash-get source-ref 'indexHint) 'backend)
               => "rust-sql")
        (check (hash-get (hash-get source-ref 'indexHint) 'missingLocalAction)
               => "install-package-before-repository-fallback")
        (check (hash-get (hash-get source-ref 'indexHint) 'fallbackPolicy)
               => "repository-source-after-install-check")
        (check (hash-get source-ref 'pathPolicy) => "runtime-resolved")))
    (test-case "poo scenario preserves mixed dependency context"
      (let* ((root ".run/extensions-poo-mixed-deps")
             (dependencies ["github.com/acme/logging"
                            "git.cons.io/mighty-gerbils/gerbil-poo"
                            "github.com/acme/metrics"])
             (_ (write-extension-project root "sample/app" dependencies))
             (index (collect-project root))
             (extension (car (project-extension-json index))))
        (check (poo-extension-active? index) => #t)
        (check (hash-get extension 'package) => "sample/app")
        (check (hash-get extension 'dependencies) => dependencies)
        (check (hash-get extension 'capabilities)
               => ["object-system"
                   "metaobject-protocol"
                   "protocols"
                   "policy-protocol"
                   "macro-governance"
                   "user-override-witness"
                   "inherited-gerbil-utils"
                   "higher-order-control"
                   "typed-combinator-style"
                   "pattern-inheritance"])))
    (test-case "poo pattern evidence is downstream extension guidance"
      (let* ((root ".run/extensions-poo-pattern-evidence")
             (_ (write-extension-project
                 root
                 "sample/app"
                 ["git.cons.io/mighty-gerbils/gerbil-poo"]))
             (index (collect-project root))
             (pattern (poo-pattern-evidence index ["poo" "class" "method" "protocol"]))
             (source-ref (hash-get pattern 'sourceRef))
             (validation (hash-get pattern 'structuralValidation))
             (selectors (hash-get pattern 'selectors))
             (first-selector (car selectors)))
        (check (hash-get pattern 'agentScenario)
               => "agent-does-not-know-gerbil-poo-object-system")
        (check (hash-get pattern 'intent)
               => "write-gerbil-poo-object-system-without-racket-or-generic-scheme-guessing")
        (check (hash-get source-ref 'kind) => "package-manager-source")
        (check (hash-get source-ref 'dependency)
               => "git.cons.io/mighty-gerbils/gerbil-poo")
        (check (hash-get (hash-get source-ref 'localSource) 'rootHint)
               => "~/.gerbil")
        (check (hash-get (hash-get source-ref 'localSource) 'missingAction)
               => "install-package-before-repository-fallback")
        (check (hash-get (hash-get source-ref 'localSource) 'installHint)
               => "gxpkg install git.cons.io/mighty-gerbils/gerbil-poo")
        (check (hash-get (hash-get source-ref 'repositorySource) 'url)
               => "https://git.cons.io/mighty-gerbils/gerbil-poo")
        (check (hash-get (hash-get source-ref 'indexHint) 'mode)
               => "local-source-before-git")
        (check (hash-get (hash-get source-ref 'indexHint) 'missingLocalAction)
               => "install-package-before-repository-fallback")
        (check (hash-get (hash-get source-ref 'indexHint) 'fallbackPolicy)
               => "repository-source-after-install-check")
        (check (hash-get source-ref 'pathPolicy) => "runtime-resolved")
        (check (not (not (member "proto.ss"
                                  (hash-get pattern 'sourceOwners))))
               => #t)
        (check (hash-get first-selector 'selector)
               => "gerbil-poo://object.ss#defclass")
        (check (hash-get validation 'valid) => #t)
        (check (hash-get validation 'schema) => "poo-pattern-evidence/v1")
        (check (hash-get validation 'diagnostics) => [])
        (check (length (hash-get pattern 'selectors)) => 16)
        (check (length (hash-get pattern 'minimalForms)) => 13)
        (check (length (hash-get pattern 'failureCases)) => 9)
        (check (not (not (member "dependency-backed-mapping"
                                  (hash-get pattern 'qualitySignals))))
               => #t)))
    (test-case "poo type validation pattern carries formal structural validation"
      (let* ((root ".run/extensions-poo-type-validation-structure")
             (_ (write-extension-project
                 root
                 "sample/app"
                 ["git.cons.io/mighty-gerbils/gerbil-poo"]))
             (index (collect-project root))
             (pattern (poo-pattern-evidence index ["poo" "sealed" "validate"]))
             (validation (hash-get pattern 'structuralValidation))
             (checks (hash-get validation 'checkedSignals)))
        (check (hash-get pattern 'id) => "poo-type-validation-sealed")
        (check (hash-get validation 'patternKind) => "type-validation")
        (check (hash-get validation 'valid) => #t)
        (check (hash-get validation 'diagnostics) => [])
        (check (not (not (member "selector-uri-grammar" checks))) => #t)
        (check (not (not (member "failure-case-coverage" checks))) => #t)
        (check (not (not (member "quality-signal-coverage" checks))) => #t)))
    (test-case "poo pattern evidence inherits gerbil-utils combinator guidance"
      (let* ((root ".run/extensions-poo-inherited-utils-pattern")
             (_ (write-extension-project
                 root
                 "sample/app"
                 ["git.cons.io/mighty-gerbils/gerbil-poo"]))
             (index (collect-project root))
             (pattern (poo-pattern-evidence index ["higher-order-control" "gerbil-utils" "inherited"]))
             (source-ref (hash-get pattern 'sourceRef))
             (import-witness (hash-get pattern 'importWitness))
             (selectors (hash-get pattern 'selectors)))
        (check (hash-get pattern 'id) => "gerbil-utils-higher-order-control")
        (check (hash-get pattern 'origin) => "inherited")
        (check (hash-get pattern 'via)
               => ["git.cons.io/mighty-gerbils/gerbil-poo"
                   "git.cons.io/mighty-gerbils/gerbil-utils"])
        (check (hash-get source-ref 'dependency)
               => "git.cons.io/mighty-gerbils/gerbil-utils")
        (check (hash-get import-witness 'module) => ":clan/base")
        (check (hash-get import-witness 'status) => "verified")
        (check (hash-get (car selectors) 'selector)
               => "gerbil-utils://base.ss#rcompose")
        (check (not (not (member "package-closure-inheritance"
                                  (hash-get pattern 'qualitySignals))))
               => #t)))
    (test-case "poo pattern evidence requires activated dependency"
      (let* ((root ".run/extensions-poo-pattern-inactive")
             (_ (write-extension-project
                 root
                 "sample/app"
                 ["git.cons.io/mighty-gerbils/gerbil-utils"]))
             (index (collect-project root)))
        (check (poo-pattern-evidence index ["poo" "class"]) => #f)))
    (test-case "gerbil-poo usage query uses logical selector registry"
      (let* ((root ".run/extensions-poo-registered-query")
             (_ (write-extension-project
                 root
                 "sample/app"
                 ["git.cons.io/mighty-gerbils/gerbil-utils"]))
             (index (collect-project root))
             (pattern (poo-pattern-evidence index ["gerbil-poo" "usage"]))
             (source-ref (hash-get pattern 'sourceRef))
             (signals (hash-get pattern 'qualitySignals))
             (selectors (hash-get pattern 'selectors)))
        (check (poo-extension-active? index) => #f)
        (check (project-extension-json index) => '())
        (check (hash-get pattern 'id) => "poo-object-system")
        (check (hash-get pattern 'origin) => "registered")
        (check (hash-get source-ref 'selectorScheme)
               => "gerbil-poo-logical-symbol")
        (check (not (not (member "gerbil-poo-logical-selector-registry"
                                  signals)))
               => #t)
        (check (not (not (member "active-extension-fact" signals)))
               => #f)
        (check (hash-get (car selectors) 'selector)
               => "gerbil-poo://object.ss#defclass")))
    (test-case "poo extension does not activate from package name alone"
      (let* ((root ".run/extensions-poo-package-name-only")
             (_ (write-extension-project
                 root
                 "clan/poo"
                 ["git.cons.io/mighty-gerbils/gerbil-utils"]))
             (index (collect-project root)))
        (check (poo-extension-active? index) => #f)
        (check (project-extension-json index) => '())
        (check (project-extension-search-lines index) => '())))
    (test-case "poo extension rejects similar dependency names"
      (let* ((root ".run/extensions-poo-negative")
             (_ (write-extension-project
                 root
                 "sample/app"
                 ["git.cons.io/mighty-gerbils/gerbil-poof"]))
             (index (collect-project root)))
        (check (poo-extension-active? index) => #f)
        (check (project-extension-json index) => '())
        (check (project-extension-search-lines index) => '())))))
;; : (-> Path PackageName (List DependencyName) Unit)
(def (write-extension-project root package-name dependencies)
  (let* ((src (string-append root "/src"))
         (package-path (string-append root "/gerbil.pkg"))
         (source-path (string-append src "/main.ss")))
    (andmap (lambda (path) (ensure-dir path) #t)
            [".run" root src])
    (write-text package-path
                (string-append
                 "(package: "
                 package-name
                 "\n depend: "
                 (dependency-list-source dependencies)
                 ")\n"))
    (write-text source-path
                (string-append "(package: " package-name "/main)\n(def answer 42)\n"))))
;; : (-> (List DependencyName) DependencyListSource )
(def (dependency-list-source dependencies)
  (string-append "(" (quoted-string-list-source dependencies) ")"))
;; : (-> (List DependencyName) QuotedStringListSource )
(def (quoted-string-list-source dependencies)
  (string-join
   (map (lambda (dependency)
          (string-append "\"" dependency "\""))
        dependencies)
   " "))
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
