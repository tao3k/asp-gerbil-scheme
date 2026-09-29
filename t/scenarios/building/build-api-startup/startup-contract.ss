((scenarioKind . process-startup)
 (attemptCount . 3)
 (maxBaselineFirstEventNanoseconds . 2500000000)
 (maxNanoseconds . 2500000000)
 (maxMedianIncrementalNanoseconds . 1500000000)
 (targetNanoseconds . 500000000)
 (targetRationale
  . "default BuildSpec policy must preserve the original 2.5-second per-attempt and 1.5-second median startup limits")
 (feature . "build-api-default-policy-startup")
 (rule . "ASP-GERBIL-SCHEME-BUILD-API-STARTUP-001")
 (optimizationFocus
  . "keep direct default policy admission bounded before the std/make planning handoff when verbose is inherited")
 (inputShape . "fresh Gerbil process loads the default policy PackageSpec and projects an empty downstream BuildSpec")
 (expectedOutcome . "the first native projection event is bounded with the full default policy closure")
 (measurementPhases "process-start" "module-expand" "package-spec-project"
                    "std-make-handoff"))
