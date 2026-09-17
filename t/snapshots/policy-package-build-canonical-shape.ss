(policyScenario
 (id "package-build-canonical-shape")
 (before (finding ("GERBIL-SCHEME-AGENT-POLICY-025"
                   "build.ss"
                   "build.ss:8-8"
                   "package-level build.ss contains forbidden build control; use std/build-script with ASP PackageSpec or a native std/make build-spec, and do not hand-write GERBIL_LOADPATH/srcdir setup, manual compiler dispatch, or runtime routing in build.ss"))
         (buildShape
          ((kind "package-build-canonical-shape")
           (nativeBuildImport ":std/make")
           (nativeBuildImportModifier "direct")
           (buildSpecEntrypoint "make")
           (manualCompilerDispatch "invoke")
           (handWrittenMain "main")
           (allowedShape
            "canonical build.ss: use std/build-script defbuild-script with an ASP PackageSpec, or use a direct std/make build-spec when the package needs ssi:/gsc:/FFI build forms")
           (disallowedShape
            "hand-written srcdir/loadpath setup, manual compiler orchestration, or runtime routing that replaces Gerbil's package build entrypoints")
           (sourceEvidence
            ("gerbil://tools/gxpkg.ss:1224-1234"
             "gerbil://std/build-script.ss:9-43"
             "gerbil://std/build-spec.ss:150-220"
             "gerbil://std/make.ss:150-190"
             "gerbil://std/make.ss:559-579"
             "src/build-api/package-spec.ss"
             "src/build-api/native-spec-support.ss"
             "gerbil://doc/reference/std/make.md:32-52"))
           (nativeFactSource
            "parser-owned moduleImportFacts plus include facts, callFacts and definitionFacts")
           (next "remove manual compiler/loadpath/srcdir control from build.ss; keep package build initialization on std/build-script or std/make over ASP Building API PackageSpec data and route runtime commands through compiled package modules"))))
 (after (r025Findings ())))
