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
(export search-test-part-11)
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
(def search-test-part-11
  (test-suite "gerbil scheme harness search part 11"
    (test-case "runtime-source search routes module sugar to versioned source"
          (let (output (search-output ["runtime-source" "module-sugar" "."]))
            (check-output-contains
             output
             ["[gerbil-search-runtime-source]"
              "|fact id=gerbil-runtime-source"
              "repository=https://git.cons.io/mighty-gerbils/gerbil"
              "stateNamespace=runtime-source/gerbil-scheme"
              "|qualitySignal id=source-index-required"
              "next=search runtime-source macro sugar module-sugar"])
            (check (not (contains? output "pending")) => #t)))
    (test-case "runtime-source search routes writeenv printer hooks to versioned source"
          (let (output (search-output ["runtime-source" "writeenv" "printer" "hook" "."]))
            (check-output-contains
             output
             ["[gerbil-search-runtime-source]"
              "|fact id=gerbil-runtime-writeenv-source"
              "active-runtime-version-to-writeenv-source-acquisition-plan"
              "agent-needs-runtime-printer-hook-facts-before-poo-writeenv-roundtrip-claims"
              "|selectorResolver scheme=gerbil-runtime-source owner=gerbil-scheme stateNamespace=runtime-source/gerbil-scheme"
              "|sourceExample id=runtime-writeenv-binding role=runtime-binding symbol=writeenv selector=gerbil-runtime-source://src/bootstrap/gerbil/builtin.ssxi.ss#writeenv"
              "head=system: operands=writeenv::t,(t::t) keywords=-"
              "|sourceExample id=runtime-write-object-owner role=runtime-printer-owner symbol=write-object selector=gerbil-runtime-source://src/bootstrap/gerbil/core/runtime.ssi#write-object"
              "|sourceComment id=builtin-primitive-comment selector=gerbil-runtime-source://src/bootstrap/gerbil/builtin.ssxi.ss#writeenv"
              "|sourceComment id=write-object-comment-boundary selector=gerbil-runtime-source://src/bootstrap/gerbil/core/runtime.ssi#write-object"
              "selector=gerbil-runtime-source://src/bootstrap/gerbil/builtin.ssxi.ss#writeenv"
              "selector=gerbil-runtime-source://src/bootstrap/gerbil/core.ssi#writeenv"
              "selector=gerbil-runtime-source://src/bootstrap/gerbil/core/runtime.ssi#write-object"
              "|failureCase id=memory-writeenv-answer"
              "|failureCase id=poo-writeenv-roundtrip-assumption"
              "|failureCase id=raw-runtime-source-search"
              "|qualitySignal id=writeenv-source-index-required"
              "|qualitySignal id=printer-hook-source-required"
              "next=search runtime-source writeenv printer hook"])
            (check (not (contains? output ".data")) => #t)
            (check (not (contains? output "pending")) => #t)))))
