((benchmarkKind . scenario-e2e)
 (max_total . 300ms)
 (target_total . 150ms)
 (regression_budget . 150ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "parser-combinator-boundary keeps manual parser-state detection parser-owned and verifies expected repair is no slower than input")
 (sampleCount . 20)
 (purpose . "R013 parser combinator scenario rejects hand-written string cursor parsers when std/parser grammar boundaries are available")
 (feature . "parser-combinator-boundary")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (optimizationFocus
  .
  "manual string cursor parser state machine to std/parser defparser grammar boundary")
 (inputShape
  .
  "single exported parser uses named-let cursor state, string-ref, substring, and inline parse errors")
 (expectedOutcome
  .
  "defparser grammar with parser-fail/parser-rewind and source-aware parse-error boundary")
 (expectedReferencePattern . "gerbil-std-parser-combinator-boundary")
 (expectedReferenceExamples
  "gerbil://std/parser/defparser.ss#defparser"
  "gerbil://std/parser/defparser.ss#parser-fail"
  "gerbil://std/parser/defparser.ss#parser-rewind"
  "gerbil://std/parser/rx-parser.ss#raise-parse-error")
 (expectedQualitySignals
  "parser-combinator-boundary"
  "manual-parser-state-machine"
  "defparser-grammar-boundary"
  "source-aware-parse-error"
  "token-construction-boundary")
 (learnedStyleSources
  "gerbil://std/parser/defparser.ss"
  "gerbil://std/parser/rx-parser.ss")
 (antiAiScaffoldIntent
  .
  "reject ad hoc string parsing state machines when a grammar-owned parser combinator boundary can express parse, rewind, failure, and token construction")
 (scenarioQualityAxes
  "parser-combinator-boundary"
  "manual-parser-state-machine"
  "source-aware-parse-error"
  "anti-ai-parser-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (tags "style" "parser" "defparser" "anti-scaffold"))
