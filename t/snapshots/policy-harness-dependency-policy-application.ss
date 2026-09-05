(policyScenario
 (id "harness-dependency-policy-application")
 (before (package ((dependencies
                    ("github.com/tao3k/agent-semantic-protocols/languages/asp-gerbil-scheme"))
                   (default "all-rules-enabled")
                   (disabledRules ())
                   (explanation #f)))
         (finding ("GERBIL-SCHEME-AGENT-POLICY-013"
                   "src/orders/core.ss"
                   "src/orders/core.ss"
                   "Scheme source owner has 2 definitions but only 0 adjacent typed-combinator-style algebraic contracts; 1 public/policy-sensitive helpers need full typed doc blocks with | doc m%, # Examples, and result comments; parser-owned quality facets require repair toward compact expression-level composition; typed-combinator-style has three criteria: adjacent Scheme-native typed block such as ;; : (-> Input Output), compact expression-level composition, and optimization-boundary comments for specialized branches")))
 (after (package ((dependencies
                   ("github.com/tao3k/agent-semantic-protocols/languages/asp-gerbil-scheme"))
                  (default "all-rules-enabled")
                  (disabledRules ("GERBIL-SCHEME-AGENT-POLICY-013"))
                  (explanation
                   "Downstream example intentionally leaves legacy order helpers unrepaired while documenting the local exception.")))
        (r013Findings ())))
