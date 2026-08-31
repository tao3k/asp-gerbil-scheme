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
(export search-test-part-7)
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
(def search-test-part-7
  (test-suite "gerbil scheme harness search part 7"
    (test-case "search lexical projects parser-owned protocol syntax facts"
          (let (output (search-output ["lexical" "defprotocol protocol <Renderable>" "owner" "tests" "--view" "seeds" "."]))
            (check (contains? output "[gerbil-search-lexical] query=defprotocol protocol <Renderable>") => #t)
            (check (contains? output "|owner path=t/fixtures/parser/complex-syntax.ss") => #t)
            (check (contains? output "recommendedNext=gerbil-scheme-harness search owner t/fixtures/parser/complex-syntax.ss") => #t)))
    (test-case "structural search default output exposes ASP-owned interface"
          (let (output (search-output ["structural" "--view" "seeds" "."]))
            (check-output-contains
             output
             ["[gerbil-search-structural]"
              "mode=interface"
              "|factInterface mode=lightweight-provider-interface"
              "|projectionVocabulary facts=macroFacts,bindingFacts,pooFormFacts,higherOrderFacts,controlFlowFacts,predicateFamilyFacts,fieldAccessPatternFacts,booleanConditionFacts,loopDriverFacts,dependencyAdapterQualityFacts,functionQualityProfiles,typedContractFacts,commentQualityFacts,dependencyUsageFacts"
              "|owner path=src/commands/search-structural.ss kind=source authority=native-parser sourceClass=runtime-source"
              "|ownerFactSummary path="
              "nextCommand=gerbil-scheme-harness search structural --owner <path> --json ."])))))
