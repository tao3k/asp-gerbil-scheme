((max_total . 100ms)
 (observed_total . 5ms)
 (target_total . 25ms)
 (regression_budget . 75ms)
 (expected_over_input_budget . 0ns)
 (expected_over_input_note
  .
  "the two passes parse the same checked-in owner and must have equivalent work")
 (observedTimings
  ((name . collect-before) (durationMs . 2) (durationNs . 2000000))
  ((name . collect-after) (durationMs . 2) (durationNs . 2000000))
  ((name . policy-before) (durationMs . 0.5) (durationNs . 500000))
  ((name . policy-after) (durationMs . 0.5) (durationNs . 500000)))
 (targetRationale
  .
  "native syntax relation traversal should remain a bounded single parse without expansion")
 (maxCollectMs . 100)
 (observedCollectMs . 5)
 (maxParseMs . 100)
 (observedParseMs . 5)
 (maxFileMs . 100)
 (observedFileMs . 5)
 (maxPhaseMs . 100)
 (observedPhaseMs . 5)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (iterations . 3)
 (unit . "ms")
 (purpose . "phase-aware Gerbil-native syntax relation completeness and parse-time regression gate")
 (feature . "native-syntax-relations")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-011")
 (optimizationFocus . "compact relation index with shared source identity and no retained native syntax root")
 (inputShape . "declarative, procedural, identifier, quoted, quasisyntax, syntax/loc, and binding forms")
 (expectedOutcome . "complete unique phase-aware emitted-call relations without binder false positives")
 (tags "parser" "native-syntax" "r011" "performance"))
