;;; -*- Gerbil -*-
;;; Boundary:
;;; - test owner records policy expectations.
;;; - Keep typed contracts and fixture intent explicit.
(import :std/test
        :asp-gerbil-scheme/src/commands/guide
        :asp-gerbil-scheme/src/commands/info
        :asp-gerbil-scheme/src/commands/search
        :asp-gerbil-scheme/src/support/args
        :asp-gerbil-scheme/src/support/io
        :std/misc/ports
        (only-in :std/text/json read-json)
        "../poo/runtime-witness"
        "./structural-index")
(export search-test-part-2)
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
(def search-test-part-2
  (test-suite "gerbil scheme harness search part 2"
    (test-case "project root removal preserves option values"
          (check (project-root ["src/checker/types.ss"
                                "."
                                "--names-only"])
                 => ".")
          (check (project-root ["extension"
                                "poo"
                                "--workspace"
                                "."])
                 => ".")
          (check (drop-project-root ["src/checker/types.ss"
                                     "."
                                     "--names-only"])
                 => ["src/checker/types.ss" "--names-only"])
          (check (drop-project-root ["extension"
                                     "poo"
                                     "--workspace"
                                     "."])
                 => ["extension" "poo" "--workspace" "."])
          (check (drop-project-root ["src/checker/types.ss"
                                     "items"
                                     "--query"
                                     "."
                     "."])
                 => ["src/checker/types.ss"
                     "items"
                     "--query"
                     "."]))
    (test-case "selector parsing supports file-level reads"
          (check (split-selector "t/fixtures/sample.ss")
                 => ["t/fixtures/sample.ss" #f #f])
          (check (split-selector "t/fixtures/sample.ss:2-4")
                 => ["t/fixtures/sample.ss" 2 4])
          (let (output (read-selector "." "t/fixtures/sample.ss"))
            (check (contains? output "(export answer make-answer)") => #t)))
    (test-case "language evidence search namespaces are explicit"
          (check (language-evidence-view? "env") => #t)
          (check (language-evidence-view? "runtime-source") => #t)
          (check (language-evidence-view? "compiler-evidence") => #t)
          (check (language-evidence-view? "lang") => #t)
          (check (language-evidence-view? "std") => #t)
          (check (language-evidence-view? "capability") => #t)
          (check (language-evidence-view? "extension") => #t)
          (check (language-evidence-view? "pattern") => #t)
          (check (language-evidence-view? "concept") => #f)
          (check (language-evidence-index-free-view? "env") => #t)
          (check (language-evidence-index-free-view? "runtime-source") => #t)
          (check (language-evidence-index-free-view? "compiler-evidence") => #t)
          (check (language-evidence-index-free-view? "lang") => #t)
          (check (language-evidence-index-free-view? "std") => #t)
          (check (language-evidence-index-free-view? "capability") => #f)
          (check (language-evidence-index-free-view? "extension") => #f)
          (check (language-evidence-index-free-view? "pattern") => #f)
          (check (language-evidence-authority "extension")
                 => "ecosystem-extension")
          (check (language-evidence-authority "env") => "active-runtime")
          (check (language-evidence-authority "runtime-source")
                 => "runtime-version-source")
          (check (language-evidence-authority "compiler-evidence")
                 => "compiler-metadata-source")
          (check (language-evidence-authority "lang") => "language-rules")
          (check (language-evidence-authority "std") => "standard-library")
          (check (language-evidence-authority "capability")
                 => "project-capability-posture")
          (check (language-evidence-authority "pattern") => "executable-pattern")
          (check (language-evidence-next "pattern" "hygienic-macro")
                 => "search pattern hygienic-macro"))
    (test-case "project contract pattern query has registry witness"
      (let (output
            (search-output
             ["pattern"
              "poo-flow-json-schema-node->object-type-contract"
              "--workspace"
              "."]))
        (check-output-contains
         output
         ["[gerbil-search-pattern] query=poo-flow-json-schema-node->object-type-contract evidenceGrade=fact authority=executable-pattern quality=verified"
          "|pattern id=project-json-schema-object-type-contract"
          "witness=project-json-schema-object-type-contract-pattern-registry"
          "symbol=poo-flow-json-schema-node->object-type-contract"
          "selector=src/utilities/contracts.ss#poo-flow-json-schema-node->object-type-contract"
          "next=search pattern json-schema-node object-type-contract"])
        (check (contains? output "|missing extension-fact,pattern-registry,runnable-witness")
               => #f)))))
