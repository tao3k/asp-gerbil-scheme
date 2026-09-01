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
(export search-test-part-4)
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
(def search-test-part-4
  (test-suite "gerbil scheme harness search part 4"
    (test-case "info command exposes configurable interface closure"
          (let ((text-output (info-output ["."]))
                (json-output (info-output ["--json" "."])))
            (check (contains? text-output "[gerbil-info] language=gerbil-scheme provider=asp-gerbil-scheme") => #t)
            (check (contains? text-output "|interface source-scope=gerbil.pkg-policy") => #t)
            (check (contains? text-output "|interface build-scope=build.ss defbuild-script targets -> runtime-roots") => #t)
            (check (contains? text-output "|agent-steering facts=macroFacts,bindingFacts,pooFormFacts,higherOrderFacts,controlFlowFacts,predicateFamilyFacts,fieldAccessPatternFacts,booleanConditionFacts,loopDriverFacts,dependencyAdapterQualityFacts,functionQualityProfiles,typedContractFacts,commentQualityFacts,dependencyUsageFacts") => #t)
            (check (contains? text-output "|agent-steering rules=GERBIL-SCHEME-AGENT-POLICY-006,R007,R008,R009,R010,R011,R012,R013,R014,R015,R016,R017") => #t)
            (check (contains? text-output "|closure self-apply=gxi build.ss test") => #t)
            (check (contains? text-output "|closure bench=asp-gerbil-scheme bench --iterations 1 --max-interface-ms 50 .") => #t)
            (check (contains? json-output "agent.semantic-protocols.asp-gerbil-scheme-info") => #t)
            (check (contains? json-output "configurableInterface") => #t)
            (check (contains? json-output "agentSteering") => #t)
            (check (contains? json-output "macro-runtime-source-witness") => #t)
            (check (contains? json-output "protocol-evidence") => #t)
            (check (contains? json-output "typed-combinator-style") => #t)
            (check (contains? json-output "engineering-comment-quality") => #t)
            (check (contains? json-output "dependency-protocol-adapter") => #t)
            (check (contains? json-output "commentQualityFacts") => #t)
            (check (contains? json-output "dependencyAdapterQualityFacts") => #t)
            (check (contains? json-output "closureCommands") => #t)))
    (test-case "guide exposes server-owned source-index boundary"
          (let (output (guide-output []))
            (check (contains? output "|policy source-index-owner=asp-server; structural-index-owner=gerbil-scheme; Source Index lookup/cache is ASP Server IPC, while Gerbil search only renders provider parser facts and never invokes an asp subprocess") => #t)
            (check (contains? output "|cmd runtime-source-acquire=asp cache runtime-source acquire --language-id gerbil-scheme") => #t)
            (check (contains? output "|cmd runtime-source-lookup=asp gerbil-scheme cache source-index lookup --query <symbol> --index-root . --limit 8") => #t)
            (check (contains? output "cache source-index lookup") => #f)))
    (test-case "guide code defaults to one source-backed pure excerpt"
          (let (output (guide-output ["--code"]))
            (check (contains? output ";;; Entry boundary: emit at most one typed-combinator finding per owner") => #t)
            (check (contains? output ";; : (-> ProjectIndex (List TypeFinding))") => #t)
            (check (contains? output "(def (typed-combinator-style-findings index)") => #t)
            (check (contains? output "(def (typed-combinator-style-function-definitions file)") => #t)
            (check (contains? output "[guide-code]") => #f)
            (check (contains? output "|primaryExemplar") => #f)
            (check (contains? output "|code begin") => #f)
            (check (contains? output "(def (poo-form-facts-from-form") => #f)))))
