((scenarioKind . process-startup)
 (attemptCount . 1)
 (maxNanoseconds . 3000000000)
 (targetNanoseconds . 1500000000)
 (targetRationale
  . "a PackageSpec-only downstream build script must start in a few seconds")
 (feature . "build-api-startup-closure")
 (rule . "ASP-GERBIL-SCHEME-BUILD-API-STARTUP-001")
 (optimizationFocus
  . "keep optional Policy testing runtime and benchmark graphs out of PackageSpec startup")
 (inputShape . "fresh Gerbil process projects an empty downstream PackageSpec")
 (expectedOutcome . "spec projection exits successfully within three seconds")
 (measurementPhases "process-start" "module-expand" "package-spec-project"))
