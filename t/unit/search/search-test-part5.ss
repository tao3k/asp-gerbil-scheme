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
(export search-test-part-5)
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
(def search-test-part-5
  (test-suite "gerbil scheme harness search part 5"
    (test-case "guide code more progressively adds a second exemplar"
          (let (output (guide-output ["--code" "--more"]))
            (check (contains? output "(def (typed-combinator-style-findings index)") => #t)
            (check (contains? output ";; : (-> ProjectIndex (List TypeFinding))") => #t)
            (check (contains? output "(def (functional-idiom-advice-findings index)") => #t)
            (check (contains? output "|exemplar") => #f)))
    (test-case "guide code scenario preserves source-quality progressive excerpts"
          (let* ((guide (guide-output []))
                 (default-output
                  (guide-output ["--code" "--topic" "higher-order-control"]))
                 (more-output
                  (guide-output ["--code" "--topic" "higher-order-control" "--more"])))
            (check (contains? guide "|guideExemplar id=gerbil.higher-order-control.filter-map topic=higher-order-control intent=study rule=GERBIL-SCHEME-AGENT-POLICY-009") => #t)
            (check (contains? guide "nextCommand=\"asp-gerbil-scheme guide --code --topic higher-order-control\"") => #t)
            (check (contains? guide "moreCommand=\"asp-gerbil-scheme guide --code --topic higher-order-control --more\"") => #t)
            (check (guide-code-render-metadata-free? default-output) => #t)
            (check (guide-code-render-metadata-free? more-output) => #t)
            (check (contains? default-output ";;; Arity checks over parser-owned call facts") => #t)
            (check (contains? default-output "filter-map") => #t)
            (check (contains? default-output "(def (call-arity-finding/known-signature signatures call)") => #t)
            (check (contains? default-output "(def (run-arity-checks index signatures)") => #t)
            (check (contains? default-output "(cut call-arity-finding/known-signature signatures <>)") => #t)
            (check (contains? default-output "(def (poo-form-facts-from-form") => #f)
            (check (contains? more-output "(def (poo-form-facts-from-form") => #t)
            (check (contains? guide "(def (run-arity-checks index signatures)") => #f)))))
