((benchmarkKind . scenario-e2e)
 (max_total . 200ms)
 (target_total . 100ms)
 (regression_budget . 100ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The actor-runtime-boundary target defines the optimization objective; max_total is the hard regression ceiling, and runtime observations belong only in measured receipts.")
 (sampleCount . 20)
 (purpose . "R013 separates Gerbil actor runtime, mailbox protocol, lifecycle, shutdown, and parameter propagation responsibilities")
 (feature . "actor-runtime-boundary")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (optimizationFocus . "actor mailbox protocol and lifecycle helper boundary")
 (inputShape
  .
  "one actor helper mixes Actor, Mailbox, Send, Receive, Spawn, Join, Shutdown, and Parameter responsibilities")
 (expectedOutcome
  .
  "split actor spawn, mailbox delivery, shutdown, and parameter-propagation helpers without adding dependency requirements")
 (expectedReferencePattern . "gerbil-actor-runtime-boundary")
 (expectedReferenceExamples
  "gerbil://std/actor-v18/executor.ss#spawn-actor-worker"
  "gerbil://std/actor-v18/server.ss#actor-server-loop"
  "gerbil://std/actor-v18/message.ss#mailbox-message"
  "gerbil://gerbil/runtime/control.ss#call-with-parameters")
 (expectedQualitySignals
  "actor-runtime-boundary"
  "mailbox-protocol-boundary"
  "actor-lifecycle-helper"
  "actor-shutdown-boundary"
  "actor-parameter-propagation")
 (learnedStyleSources
  "gerbil://std/actor-v18/executor.ss"
  "gerbil://std/actor-v18/server.ss"
  "gerbil://gerbil/runtime/control.ss")
 (antiAiScaffoldIntent
  .
  "reject all-in-one actor loops that hide mailbox protocol, lifecycle, shutdown, supervision, and parameter propagation")
 (scenarioQualityAxes
  "actor-runtime-boundary"
  "mailbox-protocol-boundary"
  "runtime-control")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (tags "style" "gerbil-native" "actor" "runtime" "mailbox"))
