((benchmarkKind . scenario-e2e)
 (max_total . 200ms)
 (target_total . 100ms)
 (regression_budget . 100ms)
 (expected_over_input_budget . 150ms)
 (expected_over_input_note
  .
  "The repaired tree intentionally separates JSON, string, bytes, and marshal protocol layers, so its policy projection may cost more than the collapsed input while remaining inside the scenario-owned comparison ceiling.")
 (targetRationale
  .
  "The protocol-serialization-boundary target defines the optimization objective; max_total is the hard regression ceiling, and runtime observations belong only in measured receipts.")
 (sampleCount . 20)
 (purpose . "R013 serialization protocol scenario keeps learned representation-layer repair within the scenario-owned timing gate")
 (feature . "protocol-serialization-boundary")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (optimizationFocus . "local JSON/string/bytes/marshal adapter boundary")
 (inputShape
  .
  "single exported function mixes JSON, String, Bytes, and Marshal representation layers")
 (expectedOutcome
  .
  "local protocol helpers split representation layers without adding gerbil-poo or gerbil-utils dependencies")
 (expectedReferencePattern . "protocol-serialization-boundary")
 (expectedReferenceExamples
  "gerbil-poo/io.ss#marshal"
  "gerbil-poo/io.ss#bytes<-"
  "gerbil-poo/io.ss#methods.marshal<-bytes")
 (expectedQualitySignals
  "self-delimited-marshal-boundary"
  "bytes-non-self-delimited-boundary"
  "local-protocol-adapter"
  "protocol-layer-scaffold-collapse")
 (learnedStyleSources "gerbil-poo" "gerbil-utils")
 (antiAiScaffoldIntent
  .
  "reject one-owner serialization scaffolding that collapses JSON, string, bytes, and marshal layers")
 (scenarioQualityAxes "protocol-serialization-boundary" "anti-ai-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (tags "style" "serialization" "protocol-boundary"))
