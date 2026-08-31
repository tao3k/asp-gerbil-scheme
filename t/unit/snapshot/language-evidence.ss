;;; -*- Gerbil -*-
;;; Boundary:
;;; - test owner records policy expectations.
;;; - Keep typed contracts and fixture intent explicit.
(import :asp-gerbil-scheme/src/commands/guide
        :asp-gerbil-scheme/src/language/facade
        :asp-gerbil-scheme/src/protocol/registry
        :asp-gerbil-scheme/src/snapshot/facade
        :std/test)

(export check-language-evidence-snapshot-fields
        check-language-evidence-snapshot-fixtures
        check-guide-and-registry-snapshot-fixtures)
;; : (-> (List String) String String )
(def (fact-by-id facts id)
  (or (find (lambda (fact)
              (equal? (hash-get fact 'id) id))
            facts)
      (error "evidence fact not found" id)))
;; String
(def (check-language-evidence-snapshot-fields)
  (let (fact (fact-by-id (standard-library-facts) "std/text/json"))
    (check (language-evidence-search-snapshot
            "std"
            "standard-library"
            "json"
            [fact]
            (hash-get fact 'next))
           => '(languageEvidenceSearch
                (namespace "std")
                (authority "standard-library")
                (evidenceGrade "fact")
                (query "json")
                (facts
                 ((languageEvidenceFact
                   (id "std/text/json")
                   (summary "Gerbil JSON parsing is available through :std/text/json; import read-json with only-in when the harness needs machine packet validation.")
                   (evidenceGrade "fact")
                   (witness "provider-imports-:std/text/json")
                   (next "search std json")
                   (details
                    (module ":std/text/json")
                    (capabilities ("read-json"))
                    (minimalImport "(import (only-in :std/text/json read-json))"))
                   (selectors ())
                   (agentScenario "agent-needs-json-packet-validation-without-python-parser")
                   (intent "use-gerbil-std-text-json-read-json-with-only-in")
                   (failureCases
                    ((failureCase
                      (id "foreign-json-parser")
                      (risk "agent-adds-python-or-shell-json-parser-for-gerbil-tests")
                      (correction "use-read-json-from-std-text-json"))
                     (failureCase
                      (id "broad-json-import")
                      (risk "agent-imports-more-json-surface-than-the-test-needs")
                      (correction "use-only-in-std-text-json-read-json"))))
                   (qualitySignals ("provider-imports-std-module"
                                    "read-json-capability"
                                    "only-in-minimal-import")))))
                (next "search std json")))))
;; String
(def (check-language-evidence-snapshot-fixtures)
  (let ((env-fact (fact-by-id (active-runtime-facts) "active-gerbil-runtime"))
        (module-fact (fact-by-id (language-rule-facts) "module-import"))
        (std-json-fact (fact-by-id (standard-library-facts) "std/text/json")))
    (check (language-evidence-search-snapshot
            "env"
            "active-runtime"
            "gxi"
            [env-fact]
            (hash-get env-fact 'next))
           => (snapshot-load "t/snapshots/language-env-runtime.ss"))
    (check (language-evidence-search-snapshot
            "lang"
            "language-rules"
            "rename-in"
            [module-fact]
            (hash-get module-fact 'next))
           => (snapshot-load "t/snapshots/language-lang-module-import.ss"))
    (check (language-evidence-search-snapshot
            "std"
            "standard-library"
            "json"
            [std-json-fact]
            (hash-get std-json-fact 'next))
           => (snapshot-load "t/snapshots/language-std-json.ss"))))
;; String
(def (check-guide-and-registry-snapshot-fixtures)
  (check (guide-snapshot (guide-lines))
         => (snapshot-load "t/snapshots/search-guide.ss"))
  (check (registry-snapshot (language-registry "."))
         => (snapshot-load "t/snapshots/registry-search-schemas.ss")))
