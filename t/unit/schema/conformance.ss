;;; -*- Gerbil -*-
;;; Boundary:
;;; - test owner records policy expectations.
;;; - Keep typed contracts and fixture intent explicit.
(import :gslph/src/commands/info
        :gslph/src/commands/search
        :gslph/src/parser/facade
        :gslph/src/protocol/json
        :std/misc/ports
        :std/srfi/13
        :std/test
        :std/text/json)

(export check-info-json-schema-conformance
        check-language-evidence-json-schema-conformance
        check-runtime-source-json-schema-conformance
        check-type-proof-json-schema-conformance
        check-extension-pattern-json-schema-conformance
        check-compare-json-schema-conformance
        check-structural-index-json-schema-conformance)
;; : (-> Table Key Json )
(def (json-get table key)
  (hash-get table key))
;; : (-> (List String) Json )
(def (search-json args)
  (let* ((status #f)
         (output
          (call-with-output-string
            (lambda (out)
              (parameterize ((current-output-port out))
                (set! status (search-main args)))))))
    (check status => 0)
    (call-with-input-string output read-json)))

(def (packet-json packet)
  (call-with-input-string
   (call-with-output-string
    (lambda (out)
      (parameterize ((current-output-port out))
        (write-json packet))))
   read-json))
;; : (-> (List String) Json )
(def (info-json args)
  (let* ((status #f)
         (output
          (call-with-output-string
            (lambda (out)
              (parameterize ((current-output-port out))
                (set! status (info-main args)))))))
    (check status => 0)
    (call-with-input-string output read-json)))
;; : (-> SourceFile Json )
(def (schema-json file)
  (call-with-input-file (string-append "schemas/" file) read-json))
;; : (-> Packet SchemaFile Integer )
(def (check-packet-conforms-to-schema! packet schema-file)
  (let (schema (schema-json schema-file))
    (check (missing-required-fields packet schema) => [])
    (for-each
     (lambda (entry)
       (check (json-get packet (car entry)) => (cdr entry)))
     (top-level-const-fields schema))))
;; : (-> Rules String Boolean )
(def (has-rule-id? rules id)
  (cond
   ((null? rules) #f)
   ((equal? (json-get (car rules) "id") id) #t)
   (else (has-rule-id? (cdr rules) id))))
;; Json
(def (check-info-json-schema-conformance)
  (let* ((packet (info-json ["--json" "t/fixtures"]))
         (steering (json-get packet "agentSteering"))
         (commands (json-get packet "closureCommands")))
    (check-packet-conforms-to-schema!
      packet
      "semantic-gerbil-scheme-harness-info.v1.schema.json")
    (check (json-get packet "files") => 0)
    (check (json-get packet "definitions") => 0)
    (check (not (not (member "macroFacts" (json-get steering "facts")))) => #t)
    (check (has-rule-id? (json-get steering "rules") "GERBIL-SCHEME-AGENT-POLICY-011") => #t)
    (check (json-get commands "selfApply")
           => "gxi build.ss")))

;; Json
(def (check-language-evidence-json-schema-conformance)
  (let* ((packet (search-json ["compiler-evidence" "assert-type" "--json" "."]))
         (facts (json-get packet "facts"))
         (fact (car facts))
         (details (json-get fact "details")))
    (check-packet-conforms-to-schema!
     packet
     "semantic-language-evidence.v1.schema.json")
    (check (json-get packet "namespace") => "compiler-evidence")
    (check (json-get packet "quality") => "verified")
    (check (json-get packet "missing") => [])
    (check (json-get fact "id")
           => "gerbil-compiler-medium-weight-evidence")
    (check (json-get details "proofBoundary")
           => "medium-weight-compiler-evidence")))
;; : (-> Packet Schema MissingRequiredFields )
(def (missing-required-fields packet schema)
  (filter (lambda (key)
            (not (hash-key? packet key)))
          (json-get schema "required")))
;; : (-> Schema TopLevelConstFields )
(def (top-level-const-fields schema)
  (filter-map
   (lambda (entry)
     (let (property (cdr entry))
       (and (hash-table? property)
            (hash-key? property "const")
            (cons (car entry) (json-get property "const")))))
   (hash->list (json-get schema "properties"))))
;; Json
(def (check-runtime-source-json-schema-conformance)
  (let* ((packet (search-json ["runtime-source" "writeenv" "printer" "hook" "--json" "."]))
         (source-ref (json-get packet "sourceRef"))
         (acquisition (json-get packet "acquisition"))
         (selector-resolver (json-get packet "selectorResolver"))
         (source-examples (json-get packet "sourceExamples"))
         (source-comments (json-get packet "sourceComments"))
         (facts (json-get packet "facts"))
         (fact (car facts)))
    (check-packet-conforms-to-schema!
     packet
     "semantic-runtime-source-acquisition.v1.schema.json")
    (check (json-get packet "quality") => "version-matched-source-plan")
    (check (string-prefix? "search runtime-source " (json-get packet "next")) => #t)
    (check (json-get source-ref "checkoutPolicy") => "exact-tag-from-active-runtime")
    (check (json-get source-ref "statePathPolicy") => "asp-state-managed")
    (check (json-get acquisition "owner") => "asp")
    (check (json-get acquisition "indexOwner") => "asp-structural-index")
    (check (json-get selector-resolver "output") => "code-with-comments")
    (check (not (null? source-examples)) => #t)
    (check (not (null? source-comments)) => #t)
    (check (json-get fact "id") => "gerbil-runtime-writeenv-source")
    (check (not (null? (json-get fact "selectors"))) => #t)
    (check (not (null? (json-get packet "failureCases"))) => #t)
    (check (not (null? (json-get packet "qualitySignals"))) => #t)))

;; Json
(def (check-type-proof-json-schema-conformance)
  (let* ((packet (search-json ["proof" "record" "--json" "."]))
         (proof-system (json-get packet "proofSystem"))
         (proofs (json-get packet "proofs"))
         (proof (car proofs))
         (profile (json-get proof "profile"))
         (proof-tree (json-get proof "proof")))
    (check-packet-conforms-to-schema!
     packet
     "semantic-type-proof.v1.schema.json")
    (check (json-get packet "namespace") => "proof")
    (check (json-get packet "quality") => "verified")
    (check (json-get proof-system "level") => "medium-weight")
    (check (json-get proof-system "model") => "TypeSpec")
    (check (json-get proof "id") => "record-width-subtype")
    (check (json-get profile "depth") => 4)
    (check (json-get profile "nodeCount") => 4)
    (check (json-get proof-tree "rule") => "record")))
;; Json
(def (check-extension-pattern-json-schema-conformance)
  (let* ((packet (search-json ["pattern" "poo" "json" "fallback" "--json" "."]))
         (mapping (json-get packet "patternMapping"))
         (source-ref (json-get mapping "sourceRef"))
         (selector-resolver (json-get mapping "selectorResolver"))
         (source-lookup (json-get mapping "sourceLookup"))
         (agent-read-order (json-get mapping "agentReadOrder"))
         (agent-action (json-get mapping "agentAction")))
    (check-packet-conforms-to-schema!
     packet
     "semantic-extension-pattern-mapping.v1.schema.json")
    (check (json-get packet "quality") => "partial")
    (check (json-get packet "missing") => ["writeenv-roundtrip-witness"])
    (check (string-prefix? "search " (json-get packet "next")) => #t)
    (check (json-get mapping "id") => "poo-io-json-fallback")
    (check (json-get source-ref "kind") => "package-manager-source")
    (check (json-get source-ref "pathPolicy") => "runtime-resolved")
    (check (json-get (json-get source-ref "localSource") "rootHint")
           => "~/.gerbil")
    (check (json-get (json-get source-ref "localSource") "missingAction")
           => "install-package-before-repository-fallback")
    (check (json-get (json-get source-ref "localSource") "installHint")
           => "gxpkg install github.com/mighty-gerbils/gerbil-poo")
    (check (json-get (json-get source-ref "repositorySource") "url")
           => "https://git.cons.io/mighty-gerbils/gerbil-poo")
    (check (json-get (json-get source-ref "indexHint") "backend")
           => "rust-sql")
    (check (json-get (json-get source-ref "indexHint") "missingLocalAction")
           => "install-package-before-repository-fallback")
    (check (json-get (json-get source-ref "indexHint") "fallbackPolicy")
           => "repository-source-after-install-check")
    (check (json-get selector-resolver "scheme")
           => "gerbil-poo-logical-symbol")
    (check (json-get selector-resolver "querySelector") => "not-direct")
    (check (json-get selector-resolver "sourceRef")
           => "package-manager-source:gxpkg:github.com/mighty-gerbils/gerbil-poo:runtime-resolved")
    (check (json-get source-lookup "order") => "local-source-before-git")
    (check (json-get source-lookup "missingLocalAction")
           => "install-package-before-repository-fallback")
    (check (json-get source-lookup "fallbackPolicy")
           => "repository-source-after-install-check")
    (check (json-get (json-get source-lookup "localSource") "status")
           => "probe-first")
    (check (json-get (json-get source-lookup "localSource") "installHint")
           => "gxpkg install github.com/mighty-gerbils/gerbil-poo")
    (check (json-get (json-get source-lookup "repositorySource") "status")
           => "fallback")
    (check (json-get (json-get source-lookup "indexHint") "mode")
           => "local-source-before-git")
    (check (json-get agent-read-order "third") => "selectorResolver")
    (check (json-get agent-read-order "fourth") => "minimalForms")
    (check (json-get agent-action "selectorUse") => "source-anchor")
    (check (json-get agent-action "missingLocalAction")
           => "install-package-before-repository-fallback")
    (check (json-get agent-action "fallback")
           => "repository-source-after-install-check")
    (check (json-get agent-action "quality") => "partial")
    (check (not (null? (json-get mapping "selectors"))) => #t)
    (check (not (null? (json-get mapping "minimalForms"))) => #t)
    (check (not (null? (json-get mapping "failureCases"))) => #t)
    (check (not (null? (json-get mapping "qualitySignals"))) => #t)))
;; Json
(def (check-compare-json-schema-conformance)
  (let* ((packet (search-json ["compare" "env" "active" "documented" "--json" "."]))
         (comparisons (json-get packet "comparisons"))
         (comparison (car comparisons))
         (left (json-get comparison "left"))
         (right (json-get comparison "right")))
    (check-packet-conforms-to-schema!
     packet
     "semantic-compare-packet.v1.schema.json")
    (check (json-get packet "quality") => "verified")
    (check (json-get packet "missing") => [])
    (check (json-get comparison "id") => "env-active-documented")
    (check (json-get comparison "result") => "active-runtime-authoritative")
    (check (json-get left "kind") => "active-runtime")
    (check (json-get right "status") => "non-authoritative")
    (check (not (null? (json-get comparison "failureCases"))) => #t)
    (check (not (null? (json-get comparison "qualitySignals"))) => #t)))
;; Integer
(def (check-structural-index-json-schema-conformance)
  (let* ((index (collect-project "t/fixtures"))
         (packet (packet-json (structural-index-packet-json index)))
         (owner-packet
          (packet-json
           (native-syntax-owner-facts-packet-json
            index
            (find-owner index "parser/complex-syntax.ss"))))
         (higher-order-packet
          (packet-json
           (native-syntax-owner-facts-packet-json
            index
            (find-owner index "parser/higher-order.ss"))))
         (syntax-facts (json-get owner-packet "facts"))
         (higher-order-facts (json-get higher-order-packet "facts"))
         (macro-fact (find-syntax-fact syntax-facts "macro" "capture-safe"))
         (import-fact (find-syntax-fact syntax-facts "import" ":std/text/json"))
         (binding-fact (find-syntax-fact syntax-facts "binding" "again"))
         (class-fact (find-syntax-fact syntax-facts "class" "<Widget>"))
         (method-fact (find-syntax-fact syntax-facts "method" ":render"))
         (case-lambda-fact
          (find-syntax-fact-field syntax-facts
                                  "function"
                                  "case-lambda"
                                  "role"
                                  "multi-arity-function"))
         (map-fact
          (find-syntax-fact-field higher-order-facts
                                  "call"
                                  "map"
                                  "role"
                                  "sequence-map")))
    (check-packet-conforms-to-schema!
     packet
     "semantic-structural-index.v1.schema.json")
    (check-packet-conforms-to-schema!
     owner-packet
     "semantic-native-syntax-fact-index.v1.schema.json")
    (check-packet-conforms-to-schema!
     higher-order-packet
     "semantic-native-syntax-fact-index.v1.schema.json")
    (check (json-get packet "rawSourceStored") => #f)
    (check (json-get packet "indexMode") => "interface")
    (check (json-get packet "heavyIndexOwner") => "asp-rust")
    (check (json-get packet "graphTurboOwner") => "asp-graph-turbo")
    (check (length (json-get packet "syntaxFacts")) => 0)
    (check (not (null? (json-get packet "nativeSyntaxFactSummaries"))) => #t)
    (check (json-get owner-packet "scope") => "owner")
    (check (json-get owner-packet "query") => "parser/complex-syntax.ss")
    (check (json-get higher-order-packet "scope") => "owner")
    (check (json-get higher-order-packet "query") => "parser/higher-order.ss")
    (check (not (null? syntax-facts)) => #t)
    (check (json-get macro-fact "source") => "native-parser")
    (check (json-get macro-fact "languageKind") => "defsyntax")
    (check (json-get import-fact "languageKind") => "module-import")
    (check (json-get binding-fact "languageKind") => "let*")
    (check (json-get (json-get class-fact "fields") "slots")
           => ["name" "count"])
    (check (json-get (json-get method-fact "fields") "receiverType")
           => "<Widget>")
    (check (json-get (json-get method-fact "fields") "specializers")
           => ["widget:<Widget>"])
    (check (json-get (json-get method-fact "fields") "dispatchArity")
           => 1)
    (check (json-get (json-get case-lambda-fact "fields") "arities")
           => [0 1])
    (check (json-get (json-get map-fact "fields") "operandCount")
           => 2)))
;; : (-> (List SyntaxFactJson) SyntaxFactKind SyntaxFactName SyntaxFactJson )
(def (find-syntax-fact facts kind name)
  (or (find (lambda (fact)
              (and (equal? (json-get fact "kind") kind)
                   (equal? (json-get fact "name") name)))
            facts)
      (error "syntax fact not found" kind name)))
;; : (-> (List SyntaxFactJson) String String String Expected FindSyntaxFactField )
(def (find-syntax-fact-field facts kind name field expected)
  (or (find (lambda (fact)
              (and (equal? (json-get fact "kind") kind)
                   (equal? (json-get fact "name") name)
                   (let (fields (json-get fact "fields"))
                     (and fields
                          (equal? (json-get fields field) expected)))))
            facts)
      (error "syntax fact field not found" kind name field expected)))
