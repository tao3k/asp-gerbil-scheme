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
                 native-build-core-count)
        (only-in "../src/testing/gxtest-context" configure-build-root!))

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
    (test-case "build root preserves the caller Gerbil path"
      (let ((caller-gerbil-path (getenv "GERBIL_PATH" #f))
            (sentinel "/tmp/asp-gerbil-scheme-caller-path-sentinel"))
        (setenv "GERBIL_PATH" sentinel)
        (configure-build-root! (current-directory))
        (check (getenv "GERBIL_PATH" #f) => sentinel)
        (setenv "GERBIL_PATH" (or caller-gerbil-path ""))
        (configure-build-root! (current-directory))))
    (test-case "empty caller Gerbil path resolves to the Gerbil default"
      (let (caller-gerbil-path (getenv "GERBIL_PATH" #f))
        (setenv "GERBIL_PATH" "")
        (check (asp-gerbil-scheme-package-build-active-gerbil-path
                (current-directory))
               => (path-expand (gerbil-home)))
        (setenv "GERBIL_PATH" (or caller-gerbil-path ""))
        (configure-build-root! (current-directory))))
    (test-case "root build owns the native library graph and dependencies"
      (let ((library-source
             (call-with-input-file "build.ss" read-all-as-string))
            (provider-source
             (call-with-input-file "build-provider.ss" read-all-as-string))
            (package-spec-source
             (call-with-input-file "src/build-api/package-spec.ss"
                                   read-all-as-string))
            (public-facade-source
             (call-with-input-file "build-api.ss" read-all-as-string)))
        (check (string-contains library-source "init-build-environment!")
               ? true)
        (check (string-contains library-source "deps:") ? true)
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
        (check (string-contains provider-source ":std/build-script") ? true)
        (check (string-contains library-source "\"./build-api\"") => #f)
        (check (string-contains provider-source "\"./build-api\"") => #f)
        (check (string-contains provider-source "source-bootstrap") => #f)
        (check (string-contains public-facade-source "source-bootstrap")
               => #f)))
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
