((benchmarkKind . scenario-e2e)
 (max_total . 200ms)
 (target_total . 100ms)
 (regression_budget . 100ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "string-append-loop-performance keeps loop-local string builder detection parser-owned and validates one linear builder boundary in a small millisecond gate")
 (sampleCount . 20)
 (purpose
  .
  "R042 string append scenario rejects generated O(n^2) render loops when an output port, string-join, or bytes/u8vector builder boundary should own concatenation")
 (feature . "string-append-loop-performance")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-042")
 (optimizationFocus
  .
  "loop-local string-append accumulation to one output-string-port, string-join fragment list, or u8vector byte buffer boundary")
 (inputShape
  .
  "one renderer walks lines and repeatedly appends to the accumulated string inside the loop")
 (expectedOutcome
  .
  "line fragments are accumulated as a list and rendered once with string-join at the boundary")
 (expectedReferencePattern . "gerbil-string-builder-loop-boundary")
 (expectedReferenceExamples
  "gerbil://std/misc/ports.ss"
  "gerbil://std/misc/string.ss"
  "gerbil://std/net/bio/buffer.ss"
  "gerbil://gambit/tests/unit-tests/13-modules/prim_string.scm")
 (expectedQualitySignals
  "string-growth-loop-performance"
  "loop-local-string-append"
  "output-string-port-boundary"
  "string-join-fragment-list"
  "anti-ai-string-builder-scaffold")
 (learnedStyleSources
  "gerbil://std/misc/ports.ss"
  "gerbil://std/misc/string.ss"
  "gerbil://std/net/bio/buffer.ss")
 (antiAiScaffoldIntent
  .
  "reject generated render loops that repeatedly copy the accumulated string with string-append")
 (scenarioQualityAxes
  "string-append-loop-performance"
  "anti-ai-string-builder-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-input-expected-comparison")
 (tags "style" "string" "loop" "builder" "performance"))
