;;; -*- Gerbil -*-
;;; gerbil scheme harness parser part 8 comment quality.

(import :std/test
        :asp-gerbil-scheme/src/extensions/facade
        :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/parser/typed-contract-scheme
        :asp-gerbil-scheme/src/protocol/json
        :asp-gerbil-scheme/src/protocol/structural-facts
        :std/srfi/13)
(import :unit/parser/parser-test-part8-support)
(export parser-test-part-8-comment-quality)

;; PolicyTest
(def parser-test-part-8-comment-quality
  (test-suite "gerbil scheme harness parser part 8 comment quality"
(test-case "comment quality preserves module comment after script shebang"
          (let* ((root (path-normalize ".run/parser-shebang-module-comment"))
                 (source-dir (string-append root "/src"))
                 (package-path (string-append root "/gerbil.pkg"))
                 (source-path (string-append source-dir "/script.ss")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir source-dir)
            (write-text package-path "(package: sample/shebang-comment)\n")
            (write-text
             source-path
             "#!/usr/bin/env gxi\n\
;;; -*- Gerbil -*-\n\
;;; Boundary:\n\
;;; - Script materializer owns runtime artifact projection.\n\
\n\
(def (main . args) args)\n")
            (let* ((file (parse-source-file root "src/script.ss"))
                   (module-fact
                    (find (lambda (fact)
                            (equal? (comment-quality-fact-target-kind fact)
                                    "module"))
                          (source-file-comment-quality-facts file))))
              (check (comment-quality-fact-comment-lines module-fact)
                     => ["Boundary:"
                         "- Script materializer owns runtime artifact projection."])
              (check (comment-quality-fact-quality module-fact)
                     => "engineering-grade"))))
(test-case "comment quality ignores scheme comment markers in typed docs"
          (let* ((root (path-normalize ".run/parser-typed-doc-semicolon"))
                 (source-dir (string-append root "/src"))
                 (package-path (string-append root "/gerbil.pkg"))
                 (source-path (string-append source-dir "/typed-doc.ss")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir source-dir)
            (write-text package-path "(package: sample/typed-doc-semicolon)\n")
            (write-text
             source-path
             ";;; -*- Gerbil -*-\n\
;;; Boundary:\n\
;;; - Module owns typed doc semicolon parsing fixtures.\n\
\n\
;;; Boundary:\n\
;;; - Parser docs may mention Scheme comment markers as syntax.\n\
;; documented-helper\n\
;;   : (-> String String)\n\
;;   | doc m%\n\
;;       `documented-helper value` describes the `;; :` signature marker.\n\
;;\n\
;;       # Examples\n\
;;       ```scheme\n\
;;       (documented-helper \"x\")\n\
;;       ;; => \"x\"\n\
;;       ```\n\
;;     %\n\
(def (documented-helper value) value)\n")
            (let* ((file (parse-source-file root "src/typed-doc.ss"))
                   (fact
                    (find (lambda (item)
                            (equal? (comment-quality-fact-target-name item)
                                    "documented-helper"))
                          (source-file-comment-quality-facts file))))
              (check (comment-quality-fact-comment-kind fact) => "boundary")
              (check (comment-quality-fact-quality fact)
                     => "engineering-grade"))))
(test-case "function quality profile distinguishes factories from wrapper drift"
          (let* ((root (path-normalize "."))
                 (file (parse-source-file root "t/fixtures/parser/higher-order.ss"))
                 (specialized-profile
                  (find-function-quality-profile
                   (source-file-function-quality-profiles file)
                   "specialized-label"))
                 (wrapper-profile
                  (find-function-quality-profile
                   (source-file-function-quality-profiles file)
                   "wrapper-label"))
                 (match-profile
                  (find-function-quality-profile
                   (source-file-function-quality-profiles file)
                   "matched-tags"))
                 (eta-profile
                  (find-function-quality-profile
                   (source-file-function-quality-profiles file)
                   "total"))
                 (match-fact
                  (find-higher-order
                   (source-file-higher-order-forms file)
                   "lambda"
                   "lambda-match-opportunity"
                   "matched-tags"))
                 (eta-fact
                  (find-higher-order
                   (source-file-higher-order-forms file)
                   "lambda"
                   "eta-wrapper-lambda"
                   "total")))
            (check (not (not (member "higher-order-constructor-abstraction"
                                      (function-quality-profile-quality-facets
                                       specialized-profile))))
                   => #t)
            (check (not (not (member "arity-specialized-function-factory"
                                      (function-quality-profile-quality-facets
                                       specialized-profile))))
                   => #t)
            (check (member "wrapper-lambda-drift"
                           (function-quality-profile-quality-facets
                            specialized-profile))
                   => #f)
            (check (not (not (member "wrapper-lambda-drift"
                                      (function-quality-profile-quality-facets
                                       wrapper-profile))))
                   => #t)
            (check (not (not (member "function-specialization-opportunity"
                                      (function-quality-profile-quality-facets
                                       wrapper-profile))))
                   => #t)
            (check (function-quality-profile-suggested-repair-class
                    wrapper-profile)
                   => "typed-combinator-style")
            (check (not (not (string-contains
                              (function-quality-profile-advice wrapper-profile)
                              "curry/rcurry")))
                   => #t)
            (check (not match-fact) => #f)
            (check (not (not (member "lambda-match-rewrite-opportunity"
                                      (function-quality-profile-quality-facets
                                       match-profile))))
                   => #t)
            (check (function-quality-profile-suggested-repair-class
                    match-profile)
                   => "typed-combinator-style")
            (check (not (not (string-contains
                              (function-quality-profile-advice match-profile)
                              "lambda-match")))
                   => #t)
            (check (not eta-fact) => #f)
            (check (not (not (member "eta-wrapper-drift"
                                      (function-quality-profile-quality-facets
                                       eta-profile))))
                   => #t)))
  ))
