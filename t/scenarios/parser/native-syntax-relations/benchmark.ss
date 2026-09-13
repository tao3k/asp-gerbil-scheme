((benchmarkKind . scenario-e2e)
 (max_total . 100ms)
 (target_total . 25ms)
 (regression_budget . 75ms)
 (expected_over_input_budget . 0ns)
 (expected_over_input_note
  .
  "the two passes parse the same checked-in owner and must have equivalent work")
 (targetRationale
  .
  "native syntax relation traversal should remain a bounded single parse without expansion")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (sampleCount . 20)
 (purpose . "phase-aware Gerbil-native syntax relation completeness and parse-time regression gate")
 (feature . "native-syntax-relations")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-011")
 (optimizationFocus . "compact relation index with shared source identity and no retained native syntax root")
 (inputShape . "declarative, procedural, identifier, quoted, quasisyntax, syntax/loc, and binding forms")
 (expectedOutcome . "complete unique phase-aware emitted-call relations without binder false positives")
 (tags "parser" "native-syntax" "r011" "performance"))
