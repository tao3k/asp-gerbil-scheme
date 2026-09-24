((scenarioKind . process-startup)
 (attemptCount . 3)
 (maxBaselineFirstEventNanoseconds . 2500000000)
 (maxNanoseconds . 2500000000)
 (maxMedianIncrementalNanoseconds . 1500000000)
 (targetNanoseconds . 500000000)
 (targetRationale
  . "three paired baseline/build samples must keep the median PackageSpec increment below 1.5 seconds, each increment below 2.5 seconds, and retain a 500-millisecond target")
 (feature . "build-api-startup-closure")
 (rule . "ASP-GERBIL-SCHEME-BUILD-API-STARTUP-001")
 (optimizationFocus
  . "keep optional Policy testing runtime and benchmark graphs out of PackageSpec startup and expose the std/make planning handoff when verbose is inherited")
 (inputShape . "fresh Gerbil process projects an empty downstream PackageSpec")
 (expectedOutcome . "the first spec projection event has a sub-1.5-second median increment and a 500-millisecond target")
 (measurementPhases "process-start" "module-expand" "package-spec-project"
                    "std-make-handoff"))
