((scenarioKind . native-package-spec-ab)
 (attemptCount . 3)
 (executor . std/make)
 (nativeTargetCount . 5)
 (aspTargetCount . 1)
 (productTarget . "probe.ss")
 (runnerLanguage . gerbil-scheme)
 (shellRunner . #f)
 (nativeBuild . "native-build.ss")
 (candidateBuild . "asp-build.ss")
 (outputIsolation . independent-empty-images)
 (warmCompileCount . 0)
 (maxProjectionOverheadSeconds . 3)
 (targetRationale
  . "Both lanes use defbuild-script and std/make; ASP removes four package sources outside the declared product closure and must reduce cold work without changing the product target.")
 (measurementPhases scenario-start spec-process-start spec-process-returned
                    compile-process-start compile-process-returned)
 (requiredEvidence upstream-revision target-count-reduction cold-seconds
                   cold-compile-counts warm-samples warm-p50))
