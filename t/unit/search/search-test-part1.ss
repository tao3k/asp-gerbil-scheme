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
(export search-test-part-1)
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
(def search-test-part-1
  (test-suite "gerbil scheme harness search part 1"
    (test-case "POO partial upgrades have runtime witnesses"
          (check-poo-runtime-witnesses))
    (test-case "owner item marker is not treated as project root"
          (check (project-root ["src/checker/types.ss"
                                "items"
                                "--query"
                                "type-compatible"
                                "--names-only"])
                 => ".")
          (check (drop-project-root ["src/checker/types.ss"
                                     "items"
                                     "--query"
                                     "type-compatible"
                                     "--names-only"
                                     "."])
                 => ["src/checker/types.ss"
                     "items"
                     "--query"
                     "type-compatible"
                     "--names-only"]))
    (test-case "guide defaults to compact basic command surface"
      (let (output (guide-output []))
        (check-output-contains
         output
         ["|cmd prime=asp-gerbil-scheme search prime --workspace . --view seeds"
          "|cmd pipe=asp-gerbil-scheme search pipe '<term>' --workspace . --view seeds"
          "|more guide-detail=asp-gerbil-scheme guide --policy | --extensions | --poo | --exemplars | --all"])
        (check (contains? output "|policy poo-thin-macro-bridge=") => #f)
        (check (contains? output "|guideExemplar id=") => #f)))
    (test-case "guide exposes heavy policy extension and POO details behind flags"
      (check-output-contains
       (guide-output ["--policy"])
       ["|policy gerbil-build-discovery=prefer :std/make + :clan/base + :clan/building all-gerbil-modules discovery"
        "|policy cli-option-composition=keep src/cli.ss as a thin dispatcher"
        "|policy protocol-surface-minimality=define the minimal protocol slot surface first"
        "|policy reusable-contract-tests=prefer small t/ owners that apply generic contract tests to type descriptors"])
      (check-output-contains
       (guide-output ["--extensions"])
       ["|cmd extension=asp-gerbil-scheme search extension <extension> [term ...] --view seeds"
        "|cmd pattern=asp-gerbil-scheme search pattern <feature-or-extension> [term ...] --view seeds"])
      (check-output-contains
       (guide-output ["--poo"])
       ["|policy poo-thin-macro-bridge=POO syntax macros such as brace/@method should stay thin syntax bridges"
        "|policy poo-slot-resolution=POO object edits must account for C3 precedence and lazy slot cache resolution"
        "|policy poo-serialization-method-family=json<-/<-json, marshal/unmarshal, bytes<-/<-bytes, and string<-/<-string should be modeled as method/type slots"]))))
