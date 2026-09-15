((benchmarkKind . scenario-e2e)
 (max_total . 200ms)
 (target_total . 100ms)
 (regression_budget . 100ms)
 (expected_over_input_budget . 100ms)
 (targetRationale
  .
  "The concurrency-control-boundary target defines the optimization objective; max_total is the hard regression ceiling, and runtime observations belong only in measured receipts.")
 (sampleCount . 20)
 (purpose . "R013 concurrency control scenario keeps learned dynamic-wind, spawn/join, and sequentialization repair within the scenario-owned timing gate")
 (feature . "concurrency-control-boundary")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (optimizationFocus
  .
  "local dynamic-wind reentry, spawn/join/mutex/race/thread-parameter boundary")
 (inputShape
  .
  "single exported function mixes Thread, Spawn, Join, Mutex, Race, and Parallel responsibilities")
 (expectedOutcome
  .
  "local concurrency helpers split scheduling responsibilities without adding gerbil-utils dependencies")
 (expectedReferencePattern . "concurrency-control-boundary")
 (expectedReferenceExamples
  "gerbil://gerbil/runtime/control.ss#make-atomic-promise"
  "gerbil://gerbil/runtime/control.ss#call-with-parameters"
  "gerbil://gerbil/runtime/control.ss#with-unwind-protect"
  "gerbil-utils/concurrency.ss#sequentialize/mutex"
  "gerbil-utils/concurrency.ss#race/list"
  "gerbil-utils/concurrency.ss#parallel-map")
 (expectedQualitySignals
  "dynamic-wind-reentry-guard"
  "unwind-cleanup-boundary"
  "spawn-join-helper-boundary"
  "mutex-sequentialization-boundary"
  "parallel-map-join-boundary")
 (learnedStyleSources "gerbil://" "gerbil-utils")
 (antiAiScaffoldIntent
  .
  "reject all-in-one thread orchestration scaffolding when contracts expose concurrency responsibilities")
 (scenarioQualityAxes "concurrency-control-boundary" "anti-ai-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  )
 (tags "style" "concurrency" "control-boundary"))
