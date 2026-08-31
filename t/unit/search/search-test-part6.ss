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
(export search-test-part-6)
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
(def search-test-part-6
  (test-suite "gerbil scheme harness search part 6"
    (test-case "guide code routes repair witness and advanced scenarios to source only"
          (let* ((repair-output
                  (guide-output ["--code"
                                 "--rule" "GERBIL-SCHEME-AGENT-POLICY-009"
                                 "--intent" "repair"]))
                 (finding-output
                  (guide-output ["--code"
                                 "--finding" "policy=GERBIL-SCHEME-AGENT-POLICY-009"
                                 "--intent" "repair"]))
                 (poo-output
                  (guide-output ["--code"
                                 "--topic" "poo-policy"
                                 "--intent" "repair"]))
                 (typed-output
                  (guide-output ["--code"
                                 "--topic" "typed-combinator-style"
                                 "--intent" "style"]))
                 (typed-more-output
                  (guide-output ["--code"
                                 "--topic" "typed-combinator-style"
                                 "--intent" "style"
                                 "--more"]))
                 (macro-output
                  (guide-output ["--code"
                                 "--topic" "macro-runtime-source"
                                 "--intent" "witness"]))
                 (role-output
                  (guide-output ["--code"
                                 "--role" "witness"]))
                 (advanced-output
                  (guide-output ["--code"
                                 "--topic" "higher-order-control"
                                 "--level" "advanced"]))
                 (dependency-output
                  (guide-output ["--code"
                                 "--rule" "GERBIL-SCHEME-AGENT-POLICY-017"
                                 "--intent" "repair"]))
                 (dependency-more-output
                  (guide-output ["--code"
                                 "--rule" "GERBIL-SCHEME-AGENT-POLICY-017"
                                 "--intent" "repair"
                                 "--more"])))
            (for-each
             (lambda (output)
               (check (guide-code-render-metadata-free? output) => #t))
             [repair-output finding-output poo-output typed-output typed-more-output macro-output role-output advanced-output dependency-output dependency-more-output])
            (check (contains? repair-output "(def (run-arity-checks index signatures)") => #t)
            (check (contains? finding-output "(def (run-arity-checks index signatures)") => #t)
            (check (contains? poo-output "(def (poo-form-facts-from-form") => #t)
            (check (contains? typed-output "(def (typed-combinator-style-findings index)") => #t)
            (check (contains? macro-output "(defrule (defsyntax-call (macro ctx formals ...) body ...)") => #t)
            (check (contains? role-output "(defrule (defsyntax-call (macro ctx formals ...) body ...)") => #t)
            (check (contains? advanced-output "(def (run-arity-checks index signatures)") => #t)
            (check (contains? advanced-output "(def (poo-form-facts-from-form") => #t)
            (check (contains? advanced-output "(defrule (defsyntax-call (macro ctx formals ...) body ...)") => #t)
            (check (contains? dependency-output "(define-type (RationalDict. @ [methods.table] Value)") => #t)
            (check (contains? dependency-output ".validate: =>") => #t)
            (check (contains? dependency-output ".sexp<-") => #t)
            (check (contains? dependency-output "(define-type (RationalSet @ [Set<-Table.])") => #t)
            (check (contains? dependency-output "(def (dependency-adapter-quality-facts-from-candidates") => #f)
            (check (contains? dependency-more-output "(def (dependency-adapter-quality-facts-from-candidates") => #t)
            (check (contains? dependency-more-output "(def (poo-form-facts-from-form") => #f)
            (check (contains? repair-output "(def (poo-form-facts-from-form") => #f)
            (check (contains? poo-output "(def (run-arity-checks index signatures)") => #f)
            (check (contains? typed-output "|code begin") => #f)
            (check (contains? typed-output "(def (functional-idiom-advice-findings index)") => #f)
            (check (contains? typed-more-output "(def (functional-idiom-advice-findings index)") => #t)
            (check (contains? macro-output "(def (matching-language-evidence-facts index namespace terms)") => #f)
            (check (contains? macro-output "(defsyntax-for-import (only-in stx)") => #f)
            (check (contains? macro-output "[gerbil-search-runtime-source]") => #f)
            (check (contains? macro-output "protocolId") => #f)
            (check (contains? macro-output "selectorResolver scheme=") => #f)))
    (test-case "search pipe routes through compact lexical frontier"
          (let (output (search-output ["pipe" "guide" "."]))
            (check (contains? output "[gerbil-search-lexical] query=guide") => #t)
            (check (contains? output "recommendedNext=asp-gerbil-scheme search owner") => #t)))))
