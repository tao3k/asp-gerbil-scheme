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
(export search-test-part-10)
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
;; : (-> String EnsureDir )
(def (ensure-dir path)
  (with-catch
   (lambda (_) #f)
   (lambda () (create-directory path))))
;; : (-> String SourceLine Unit )
(def (write-text path text)
  (with-catch
   (lambda (_) #f)
   (lambda () (delete-file path)))
  (call-with-output-file path
    (lambda (port) (display text port))))
;; : (-> Unit Root )
(def (write-runtime-source-fixture)
  (let* ((root ".run/guide-runtime-source")
         (std-root (string-append root "/.data/gerbil/src/std"))
         (source-path (string-append std-root "/sugar.ss")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir (string-append root "/.data"))
    (ensure-dir (string-append root "/.data/gerbil"))
    (ensure-dir (string-append root "/.data/gerbil/src"))
    (ensure-dir std-root)
    (write-text
     source-path
     ";;; -*- Gerbil -*-\n;;; Fixture comment for runtime-source guide routing.\n(defrule (defsyntax-call (macro ctx formals ...) body ...)\n  (defsyntax (macro stx)\n    #'(fixture-runtime-source macro)))\n")
    root))
;; SearchTest
;; TestSuite
(def search-test-part-10
  (test-suite "gerbil scheme harness search part 10"
    (test-case "runtime-source search exposes ASP acquisition plan"
          (let (output (search-output ["runtime-source" "macro" "."]))
            (check-output-contains
             output
             ["[gerbil-search-runtime-source]"
              "|fact id=gerbil-runtime-source"
              "evidenceGrade=fact"
              "runtime-version-source"
              "active-runtime-version-to-source-acquisition-plan"
              "|sourceRef kind=runtime-version-source"
              "repository=https://git.cons.io/mighty-gerbils/gerbil"
              "checkoutPolicy=exact-tag-from-active-runtime"
              "statePathPolicy=asp-state-managed"
              "|acquisition owner=asp"
              "operation=clone-or-fetch-checkout-index"
              "stateNamespace=runtime-source/gerbil-scheme"
              "indexOwner=asp-structural-index"
              "|selectorResolver scheme=gerbil-runtime-source owner=asp stateNamespace=runtime-source/gerbil-scheme"
              "selectorFormat=gerbil-runtime-source://<source-path>#<symbol> output=code-with-comments"
              "|sourceExample id=std-sugar-defrule role=macro-rule symbol=defrule selector=gerbil-runtime-source://src/std/sugar.ss#defrule"
              "head=defrule operands=(<name> arg ...),body ... keywords=-"
              "|sourceExample id=std-sugar-defsyntax-call role=procedural-macro-call symbol=defsyntax-call selector=gerbil-runtime-source://src/std/sugar.ss#defsyntax-call"
              "|sourceExample id=module-sugar-only-in role=import-filter symbol=only-in selector=gerbil-runtime-source://src/gerbil/core/module-sugar.ss#only-in"
              "|sourceComment id=std-sugar-comment-boundary selector=gerbil-runtime-source://src/std/sugar.ss#defsyntax-call"
              "fallback=comment-missing-is-signal"
              "|selector role=std-sugar-source symbol=defrule selector=gerbil-runtime-source://src/std/sugar.ss#defrule"
              "|selector role=module-sugar-import-filter symbol=only-in selector=gerbil-runtime-source://src/gerbil/core/module-sugar.ss#only-in"
              "clone-active-runtime-source-before-answering-language-or-macro-usage"
              "|failureCase id=memory-language-answer"
              "|failureCase id=wrong-runtime-version"
              "|failureCase id=unindexed-source-checkout"
              "|qualitySignal id=no-memory"
              "|qualitySignal id=version-matched-source"
              "|qualitySignal id=asp-state-managed-checkout"
              "|qualitySignal id=code-with-comments-output"
              "|qualitySignal id=selector-resolver-owned-by-asp"
              "|qualitySignal id=source-ranking-prefers-runtime-source"
              "|qualitySignal id=bootstrap-stubs-labelled"
              "next=search runtime-source macro sugar module-sugar"])
            (check (not (contains? output ".data")) => #t)
            (check (not (contains? output "pending")) => #t)))
    (test-case "runtime-source search routes std sugar to versioned source"
          (let (output (search-output ["runtime-source" "sugar" "."]))
            (check-output-contains
             output
             ["[gerbil-search-runtime-source]"
              "|fact id=gerbil-runtime-source"
              "repository=https://git.cons.io/mighty-gerbils/gerbil"
              "|qualitySignal id=source-index-required"
              "next=search runtime-source macro sugar module-sugar"])
            (check (not (contains? output "pending")) => #t)))
    (test-case "guide code runtime-source positional query resolves versioned std source"
          (let* ((root (write-runtime-source-fixture))
                 (output
                  (parameterize ((current-directory root))
                    (guide-output ["--code" "runtime-source" "macro" "."]))))
            (check-output-contains
             output
             ["Fixture comment for runtime-source guide routing"
              "(defrule (defsyntax-call"])
            (check (contains? output "typed-combinator-style-findings") => #f)
            (check (guide-code-render-metadata-free? output) => #t)))))
