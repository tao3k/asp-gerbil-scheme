;;; -*- Gerbil -*-
;;; Package-library native build ownership contracts.

(import :gerbil/gambit
        (only-in :std/test test-suite test-case check)
        (only-in :std/misc/path path-expand)
        (only-in :std/misc/ports read-all-as-string)
        (only-in :std/srfi/13 string-contains)
        (only-in :std/source gerbil-home)
        (only-in "../src/build-api/package-build"
                 asp-gerbil-scheme-package-build-active-gerbil-path)
        (only-in "../src/build-api/core-capacity"
                 native-build-core-count))

(export package-build-contract-test)

(def package-build-contract-test
  (test-suite "asp gerbil-scheme package build contract"
    (test-case "native core capacity uses a positive override or host capacity"
      (check (native-build-core-count "4" 12) => 4)
      (check (native-build-core-count #f 12) => 12)
      (check (native-build-core-count "" 12) => 12)
      (check (native-build-core-count "invalid" 12) => 12)
      (check (native-build-core-count "0" 12) => 12)
      (check (native-build-core-count #f 0) => 1))
    (test-case "empty caller Gerbil path resolves to the Gerbil default"
      (let (caller-gerbil-path (getenv "GERBIL_PATH" #f))
        (setenv "GERBIL_PATH" "")
        (check (asp-gerbil-scheme-package-build-active-gerbil-path
                (current-directory))
               => (path-expand (gerbil-home)))
        (setenv "GERBIL_PATH" (or caller-gerbil-path ""))))
    (test-case "root build owns the native library graph and dependencies"
      (let ((library-source
             (call-with-input-file "build.ss" read-all-as-string))
            (provider-source
             (call-with-input-file "build-provider.ss" read-all-as-string))
            (package-spec-source
             (call-with-input-file "src/build-api/package-spec.ss"
                                   read-all-as-string))
            (provider-package-spec-source
             (call-with-input-file "provider-package-spec.ss"
                                   read-all-as-string))
            (public-facade-source
             (call-with-input-file "build-api.ss" read-all-as-string))
            (building-api-source
             (call-with-input-file "building-api.ss" read-all-as-string))
            (testing-api-source
             (call-with-input-file "testing-api.ss" read-all-as-string))
            (policy-api-source
             (call-with-input-file "policy-api.ss" read-all-as-string))
            (benchmark-api-source
             (call-with-input-file "benchmark-api.ss" read-all-as-string)))
        (check (string-contains library-source "defbuild-script")
               ? true)
        (check (string-contains library-source "init-build-environment!") => #f)
        (check (string-contains library-source "all-gerbil-modules")
               ? true)
        (check (string-contains library-source
                                "(exclude-dirs => append '(\"build\"))")
               => #f)
        (check (string-contains
                library-source
                "(modules (all-gerbil-modules))")
               ? true)
        (check (string-contains package-spec-source
                                "upstream-default-exclude-dirs")
               ? true)
        (check (string-contains library-source "product-entry-modules")
               ? true)
        (for-each
         (lambda (provider-only-module)
           (check (string-contains library-source provider-only-module)
                  ? true))
         '("src/runtime/provider/types"
           "src/runtime/provider/objects"
           "src/runtime/provider/interface"
           "src/runtime/provider-operation"
           "src/runtime/provider-http-json-server"))
        (for-each
         (lambda (library-owned-module)
           (check (string-contains library-source library-owned-module)
                  => #f))
         '("src/protocol/provider-operation-catalog"
           "src/protocol/registry"
           "src/commands/agent"))
        (check (string-contains
                library-source
                "\"./src/build-api/source-bootstrap\"")
               ? true)
        (check (string-contains library-source
                                "initialize-native-build-core-capacity!")
               => #f)
        (check (string-contains provider-source
                                "initialize-native-build-core-capacity!")
               => #f)
        (check (string-contains package-spec-source
                                "initialize-native-build-core-capacity!")
               ? true)
        (check (string-contains provider-source "defbuild-script")
               ? true)
        (check (string-contains provider-source "init-build-environment!") => #f)
        (check (string-contains package-spec-source "pkg-config-options") => #f)
        (check (string-contains provider-package-spec-source
                                "pkg-config-options")
               ? true)
        (check (string-contains library-source "define-entry-point") => #f)
        (check (string-contains provider-source "define-entry-point") => #f)
        (check (string-contains provider-package-spec-source "cppflags")
               => #f)
        (check (string-contains provider-package-spec-source "ldflags")
               => #f)
        (check (string-contains provider-package-spec-source "-cc-options")
               => #f)
        (check (string-contains provider-package-spec-source "-ld-options")
               => #f)
        (check (string-contains library-source "\"./build-api\"") => #f)
        (check (string-contains provider-source "\"./build-api\"") => #f)
        (check (string-contains provider-source "source-bootstrap") ? true)
        (check (string-contains public-facade-source "source-bootstrap")
               => #f)
        (check (string-contains public-facade-source
                                "./src/build-api/source-closure")
               => #f)
        (check (string-contains public-facade-source
                                "./src/build-api/source-coverage")
               => #f)
        (for-each
         (lambda (forbidden-owner)
           (check (string-contains public-facade-source forbidden-owner)
                  => #f))
         '("./src/building/"
           "./src/testing/"
           "./src/policy/"
           "./src/benchmark/"
           ":clan/testing"))
        (check (string-contains public-facade-source
                                "./src/build-api/package-spec")
               ? true)
        (check (string-contains building-api-source "./src/building/facade")
               ? true)
        (check (string-contains testing-api-source "./src/testing/extension")
               ? true)
        (check (string-contains policy-api-source "./src/policy/gxtest")
               ? true)
        (check (string-contains benchmark-api-source "./src/benchmark/gate")
               ? true)
        (for-each
         (lambda (duplicate-owner)
           (check (string-contains public-facade-source duplicate-owner)
                  => #f))
         '("./src/testing/build-runner"
           "./src/testing/build"
           "./src/testing/framework"
           "./src/testing/model"
           "./src/testing/gxtest-runner"
           "./src/testing/gxtest-discovery"
           "./src/testing/selection"
           "./src/testing/scope"))
        ))
    (test-case "retired duplicate native owners stay absent"
      (for-each
       (lambda (path)
         (check (file-exists? path) => #f))
       '("library-package-spec.ss"
         "src/build-api/artifact-cleanup.ss"
         "src/build-api/build-environment-profile.ss"
         "src/build-api/builder-profile.ss"
         "src/build-api/native-build.ss"
         "src/build-api/native-build-spec.ss"
         "src/build-api/package-native-plan.ss"
         "src/build-api/profile-build-spec.ss"
         "src/build-api/project-build.ss"
         "src/build-api/source-discovery.ss"
         "src/building/build-script.ss"
         "src/building/build-script-body.inc"
         "src/building/native-toolchain.ss")))))
