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
(export search-test-part-13)
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
(def search-test-part-13
  (test-suite "gerbil scheme harness search part 13"
    (test-case "compare search prefers active runtime over documented claims"
          (let (output (search-output ["compare" "env" "active" "documented" "."]))
            (check-output-contains
             output
             ["[gerbil-search-compare]"
              "evidenceGrade=fact"
              "authority=active-runtime-vs-documented"
              "quality=verified"
              "|compare id=env-active-documented result=active-runtime-authoritative"
              "witness=active-runtime-beats-documented-memory"
              "|left kind=active-runtime"
              "gxiResolved=#t"
              "gscResolved=#t"
              "|right kind=documented-runtime source=documentation-or-model-memory status=non-authoritative"
              "|failureCase id=documented-version-wins"
              "|failureCase id=compare-leaks-local-path"
              "|qualitySignal id=active-runtime-fact"
              "|qualitySignal id=path-free-compare-output"
              "next=search env gxi load-path"])
            (check (not (contains? output ".data")) => #t)
            (check (not (contains? output "/Users/")) => #t)
            (check (not (contains? output "/opt/homebrew")) => #t)))
    (test-case "compare search routes compile target versions to runtime source"
          (let (output (search-output ["compare" "compile" "v0.18" "v0.19" "nightly" "."]))
            (check-output-contains
             output
             ["[gerbil-search-compare]"
              "evidenceGrade=fact"
              "quality=verified"
              "|compare id=compile-target-runtime-source result=active-runtime-source-checkout-required-before-version-guidance"
              "witness=active-runtime-selects-versioned-source-before-compile-guidance"
              "|left kind=active-runtime"
              "|right kind=requested-compile-target source=agent-request-or-user-claim status=non-authoritative-until-runtime-source-acquired"
              "|compareTargets versions=v0.18,v0.19,nightly compileMode=active-gxi-gsc-first stateNamespace=runtime-source/gerbil-scheme"
              "|agentScenario id=agent-needs-to-answer-gerbil-compile-or-syntax-question-for-a-requested-version"
              "|failureCase id=requested-version-wins-without-runtime"
              "|failureCase id=compile-source-mismatch"
              "|failureCase id=nightly-assumption"
              "|qualitySignal id=compile-version-query"
              "|qualitySignal id=version-matched-source"
              "|qualitySignal id=source-checkout-required"
              "next=search runtime-source macro sugar module-sugar"])
            (check (not (contains? output ".data")) => #t)
            (check (not (contains? output "/Users/")) => #t)
            (check (not (contains? output "/opt/homebrew")) => #t)))))
