((scenarioKind . process-startup)
 (attemptCount . 1)
 (maxBaselineFirstEventNanoseconds . 2500000000)
 (maxNanoseconds . 4000000000)
 (targetNanoseconds . 1500000000)
 (targetRationale
  . "a PackageSpec-only downstream build script must add less than four seconds over an independently bounded empty Gerbil process while retaining a 1.5-second target")
 (feature . "build-api-startup-closure")
 (rule . "ASP-GERBIL-SCHEME-BUILD-API-STARTUP-001")
 (optimizationFocus
  . "keep optional Policy testing runtime and benchmark graphs out of PackageSpec startup and expose the std/make planning handoff when verbose is inherited")
 (inputShape . "fresh Gerbil process projects an empty downstream PackageSpec")
 (expectedOutcome . "the first spec projection event appears within four incremental seconds")
 (measurementPhases "process-start" "module-expand" "package-spec-project"
                    "std-make-handoff"))
