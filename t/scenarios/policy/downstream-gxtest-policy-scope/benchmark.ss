((benchmarkKind . scenario-e2e)
 (max_total . 300ms)
 (target_total . 150ms)
 (regression_budget . 150ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "downstream gxtest policy scope runs twenty samples through the real import-closure boundary; the target covers normal parser and policy work, the independent input/expected p95 comparison allows 100ms of measured tree-shape and allocator variance, and explicit total headroom absorbs scheduler tail latency")
 (sampleCount . 20)
 (purpose
  .
  "R013 downstream gxtest scenario reproduces unit-tests importing project-policy-test while source warnings live behind another imported test")
 (feature . "downstream-gxtest-policy-scope")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (optimizationFocus
  .
  "gxtest files-scope import closure must include tested package-local source owners")
 (inputShape
  .
  "unit-tests imports project-policy-test and provider-entry-test; provider-entry-test imports src/provider-entry where the R013 warning lives")
 (expectedOutcome
  .
  "gxtest policy report on unit-tests sees src/provider-entry before repair and passes after the source owner uses fold style")
 (expectedReferencePattern . "loop-driver-combinator-boundary")
 (expectedReferenceExamples
  "gerbil://std/actor-v13/rpc/proto/cipher.ss#foldl-chunk-accumulator"
  "gerbil-utils/base.ss#lambda-match")
 (expectedQualitySignals
  "basic-syntax-scaffold"
  "manual-loop-drift"
  "pure-loop-driver-combinator-boundary"
  "fold-reducer-boundary")
 (learnedStyleSources "gerbil://" "gerbil-utils")
 (antiAiScaffoldIntent
  .
  "reject a green gxtest result when the policy suite only checks the project-policy module and misses source owners reached by the real unit test root")
 (scenarioQualityAxes
  "downstream-gxtest"
  "gxtest-policy-scope"
  "gerbil-gambit-native-idiom"
  "anti-ai-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (tags "style"
       "gxtest"
       "downstream"
       "scope"
       "import-closure"
       "anti-scaffold"))
