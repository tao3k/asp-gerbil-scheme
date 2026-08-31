(import :std/test
        :asp-gerbil-scheme/src/parser/facade)

(export typed-contract-macro-boundary-test)

(def typed-contract-macro-boundary-test
  (test-suite "asp gerbil-scheme macro contract boundary"
    (test-case "treats defrules contracts as syntax, not zero-arity runtime calls"
      (let* ((file (parse-source-file "." "src/building/declarative.ss"))
             (facts (source-file-typed-contract-facts file)))
        (check (map typed-contract-fact-definition-kind facts)
               => '("defrules" "defrules" "defrules" "defrules"))
        (check (map typed-contract-fact-arity-alignment facts)
               => '("macro-syntax" "macro-syntax" "macro-syntax" "macro-syntax"))))))
