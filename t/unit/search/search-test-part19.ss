;;; -*- Gerbil -*-
;;; Boundary:
;;; - test owner records policy expectations.
;;; - Keep typed contracts and fixture intent explicit.
(import :std/test
        :asp-gerbil-scheme/src/commands/guide
        :asp-gerbil-scheme/src/commands/info
        :asp-gerbil-scheme/src/commands/search
        :asp-gerbil-scheme/src/support/args
        :std/misc/ports
        (only-in :std/text/json read-json)
        "../poo/runtime-witness"
        "./structural-index")
(export search-test-part-19)
;; : (-> Table Key Json )
(def (json-get table key)
  (hash-get table key))
;; : (-> (List String) String )
(def (search-output args)
  (let* ((status #f)
         (output
          (call-with-output-string
            (lambda (out)
              (parameterize ((current-output-port out))
                (set! status (search-main args)))))))
    (check status => 0)
    output))
;; : (-> (List String) String )
(def (guide-output args)
  (let* ((status #f)
         (output
          (call-with-output-string
            (lambda (out)
              (parameterize ((current-output-port out))
                (set! status (guide-main args)))))))
    (check status => 0)
    output))
;; : (-> (List String) String )
(def (info-output args)
  (let* ((status #f)
         (output
          (call-with-output-string
            (lambda (out)
              (parameterize ((current-output-port out))
                (set! status (info-main args)))))))
    (check status => 0)
    output))
;; : (-> OutputPort Fragment Boolean )
(def (contains? output fragment)
  (and (string-contains output fragment) #t))
;; : (-> OutputPort Boolean )
(def (guide-code-render-metadata-free? output)
  (not (or (contains? output "[guide")
           (contains? output "|primaryExemplar")
           (contains? output "|exemplar")
           (contains? output "|code begin")
           (contains? output "selector=")
           (contains? output "nextCommand=")
           (contains? output "\n|"))))
;; : (-> OutputPort Fragments Boolean )
(def (check-output-contains output fragments)
  (for-each
   (lambda (fragment)
     (check (contains? output fragment) => #t))
   fragments))
;; SearchTest
;; TestSuite
(def search-test-part-19
  (test-suite "gerbil scheme harness search part 19"
    (test-case "pattern json reports inherited gerbil-utils pattern origin"
          (let* ((output (search-output
                          ["pattern" "higher-order-control" "gerbil-utils" "inherited" "--json" "."]))
                 (packet (call-with-input-string output read-json))
                 (mapping (json-get packet "patternMapping"))
                 (source-ref (json-get mapping "sourceRef"))
                 (import-witness (json-get mapping "importWitness"))
                 (selectors (json-get mapping "selectors"))
                 (forms (json-get mapping "minimalForms")))
            (check (json-get packet "schemaId")
                   => "agent.semantic-protocols.semantic-extension-pattern-mapping")
            (check (json-get packet "quality") => "verified")
            (check (json-get packet "missing") => [])
            (check (json-get mapping "id") => "gerbil-utils-higher-order-control")
            (check (json-get mapping "extension") => "poo")
            (check (json-get mapping "origin") => "inherited")
            (check (json-get mapping "via")
                   => ["git.cons.io/mighty-gerbils/gerbil-poo"
                       "git.cons.io/mighty-gerbils/gerbil-utils"])
            (check (json-get source-ref "dependency")
                   => "git.cons.io/mighty-gerbils/gerbil-utils")
            (check (json-get import-witness "module") => ":clan/base")
            (check (json-get import-witness "status") => "verified")
            (check (json-get import-witness "dependencyChain")
                   => ["git.cons.io/mighty-gerbils/gerbil-poo"
                       "git.cons.io/mighty-gerbils/gerbil-utils"])
            (check (json-get (list-ref selectors 3) "selector")
                   => "gerbil-utils://base.ss#curry")
            (check (json-get (json-get (list-ref forms 2) "template") "head")
                   => "fold<-reduce-map")))
    (test-case "pattern json reports runtime witness quality for POO trace debug"
          (let* ((output (search-output ["pattern" "poo" "trace" "debug" "--json" "."]))
                 (packet (call-with-input-string output read-json))
                 (mapping (json-get packet "patternMapping"))
                 (source-ref (json-get mapping "sourceRef"))
                 (selectors (json-get mapping "selectors"))
                 (computed-selector (list-ref selectors 3))
                 (forms (json-get mapping "minimalForms"))
                 (computed-form (list-ref forms 2))
                 (failures (json-get mapping "failureCases"))
                 (first-failure (car failures)))
            (check (json-get packet "schemaId")
                   => "agent.semantic-protocols.semantic-extension-pattern-mapping")
            (check (json-get packet "namespace") => "pattern")
            (check (json-get packet "quality") => "verified")
            (check (json-get packet "missing") => [])
            (check (json-get packet "witness") => "runtime-trace-poo-witness")
            (check (json-get packet "next") => "search pattern poo trace runtime witness")
            (check (json-get mapping "id") => "poo-trace-debug")
            (check (json-get mapping "sourceWorkspace") => #f)
            (check (json-get source-ref "pathPolicy") => "runtime-resolved")
            (check (json-get source-ref "dependency")
                   => "git.cons.io/mighty-gerbils/gerbil-poo")
            (check (json-get computed-selector "role") => "computed-slot-wrapper")
            (check (json-get computed-selector "selector")
                   => "gerbil-poo://debug.ss#trace-inherited-slot")
            (check (json-get computed-form "role") => "computed-slot-trace")
            (check (json-get (json-get computed-form "template") "keywords")
                   => ["call-superfun-before-wrapping"])
            (check (json-get first-failure "riskKind") => "computed-slot-contract")
            (check (json-get first-failure "badPattern")
                   => "trace-wrapper-that-never-calls-inherited-superfun")))))
