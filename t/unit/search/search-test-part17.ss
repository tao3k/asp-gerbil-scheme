;;; -*- Gerbil -*-
;;; Boundary:
;;; - test owner records policy expectations.
;;; - Keep typed contracts and fixture intent explicit.
(import :std/test
        :gslph/src/commands/guide
        :gslph/src/commands/info
        :gslph/src/commands/search
        :gslph/src/support/args
        :std/misc/ports
        (only-in :std/text/json read-json)
        "../poo/runtime-witness"
        "./structural-index")
(export search-test-part-17)
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
(def search-test-part-17
  (test-suite "gerbil scheme harness search part 17"
    (test-case "agent scenario warns when macro syntax would violate generated-code policy"
          (let ((lang-output (search-output ["lang" "how" "macro" "syntax-case" "defsyntax" "."]))
                (pattern-output (search-output ["pattern" "I" "need" "macro" "syntax-case" "."])))
            (check-output-contains
             lang-output
             ["|fact id=hygienic-macro"
              "|agentScenario id=agent-does-not-know-gerbil-macro-phase-rules"
              "|selector role=macro-form-parser symbol=defsyntax selector=src/checker/forms.ss:13"
              "|failureCase id=generated-code-forbidden-form"
              "|qualitySignal id=forbidden-form-policy"])
            (check-output-contains
             pattern-output
             ["|pattern id=hygienic-macro"
              "|agentScenario id=agent-does-not-know-gerbil-macro-syntax-or-generated-code-policy"
              "|selector role=std-sugar-rule-macro symbol=defrule selector=gerbil-runtime-source://src/std/sugar.ss#defrule"
              "|selector role=std-sugar-phase-import symbol=for-syntax selector=gerbil-runtime-source://src/std/sugar.ss#import-for-syntax"
              "|form role=macro-policy symbol=syntax-case"
              "|form role=std-sugar-rule-macro symbol=defrule head=defrule"
              "|form role=std-sugar-procedural-macro symbol=defsyntax-call head=defsyntax-call"
              "|failureCase id=generated-code-forbidden-form"
              "|qualitySignal id=runtime-source-std-sugar"
              "|qualitySignal id=for-syntax-import-witness"
              "|qualitySignal id=generated-code-policy"
              "quality verified missing=-"])
            (check (not (contains? pattern-output "pending")) => #t)))
    (test-case "agent scenario validates env and std quality before dialect guessing"
          (let ((env-output (search-output ["env" "which" "gxi" "load" "path" "."]))
                (std-output (search-output ["std" "how" "string" "prefix" "contains" "."]))
                (json-output (search-output ["std" "how" "parse" "json" "read-json" "."])))
            (check-output-contains
             env-output
             ["|fact id=active-gerbil-runtime"
              "|agentScenario id=agent-needs-active-gerbil-runtime-before-import-or-macro-claims"
              "|runtime gerbilHome="
              "gxiExists=#t"
              "gscExists=#t"
              "|failureCase id=stale-doc-runtime"
              "|qualitySignal id=active-gxi"
              "|qualitySignal id=runtime-load-path"])
            (check-output-contains
             std-output
             ["|fact id=std/srfi/13"
              "|agentScenario id=agent-does-not-know-gerbil-standard-string-module"
              "provider-imports-:std/srfi/13"
              "|failureCase id=guessed-racket-string-api"
              "|qualitySignal id=string-prefix-capability"
              "|qualitySignal id=string-contains-capability"])
            (check-output-contains
             json-output
             ["|fact id=std/text/json"
              "|agentScenario id=agent-needs-json-packet-validation-without-python-parser"
              "provider-imports-:std/text/json"
              "|failureCase id=foreign-json-parser"
              "|failureCase id=broad-json-import"
              "|qualitySignal id=read-json-capability"
              "|qualitySignal id=only-in-minimal-import"])
            (check (not (contains? std-output "pending")) => #t)))))
