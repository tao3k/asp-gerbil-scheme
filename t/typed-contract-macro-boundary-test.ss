(import :std/test
        :asp-gerbil-scheme/src/parser/facade)

(export typed-contract-macro-boundary-test)

(def typed-contract-macro-boundary-test
  (test-suite "asp gerbil-scheme macro contract boundary"
    (test-case "treats defrules contracts as syntax, not zero-arity runtime calls"
      (let* ((file (parse-source-file "." "src/build-api/package-spec.ss"))
             (facts (source-file-typed-contract-facts file))
             (macro-fact (car facts)))
        (check (typed-contract-fact-definition-kind macro-fact)
               => "defrules")
        (check (typed-contract-fact-arity-alignment macro-fact)
               => "macro-syntax")))))
