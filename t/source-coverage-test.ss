;;; -*- Gerbil -*-
;;; Source coverage declaration contract tests.

(import :std/test
        (only-in :std/misc/path path-normalize)
        "../src/build-api/source-coverage"
        "../src/build-api/build-path-contract")
(export source-coverage-test)

(def source-coverage-test
  (test-suite "asp-gerbil-scheme source coverage contract"
    (test-case "source coverage files follow the build declaration"
      (configure-build-root! (current-directory))
      (asp-gerbil-scheme-source-coverage
       roots: '("src" "t")
       exclude-directories: '("scenarios" "snapshots")
       files: '("t/policy-test.ss"
                "t/policy/agent-source-scope-test.ss"
                "src/policy/gxtest.ss"
                "src/building/build-script-body.inc"
                "src/build-api/native-build.ss"))
      (let (files (asp-gerbil-scheme-source-coverage-files (current-directory)))
        (check (member "t/policy-test.ss" files) ? true)
        (check (member "t/policy/agent-source-scope-test.ss" files) ? true)
        (check (member "src/policy/gxtest.ss" files) ? true)
        (check (member "src/building/build-script-body.inc" files) ? true)
        (check (member "src/build-api/native-build.ss" files) ? true)))
    (test-case "declared module catalog is reused without directory discovery"
      (asp-gerbil-scheme-source-coverage
       roots: '("src")
       files: '("src/build-api/source-coverage.ss"
                "src/build-api/package-spec.ss"))
      (check (asp-gerbil-scheme-source-coverage-files (current-directory))
             => '("src/build-api/package-spec.ss"
                  "src/build-api/source-coverage.ss"))
      (check (asp-gerbil-scheme-source-coverage-files ".")
             => '("src/build-api/package-spec.ss"
                  "src/build-api/source-coverage.ss")))
    (test-case "source coverage declaration keeps one root catalog and excludes"
      (configure-build-root! (current-directory))
      (asp-gerbil-scheme-source-coverage
       roots: '("src" "t")
       exclude-directories: '("fixtures"))
      (check (asp-gerbil-scheme-source-coverage-roots) => '("src" "t"))
      (check (asp-gerbil-scheme-source-coverage-exclude-directories)
             => '("fixtures"))
      (check (asp-gerbil-scheme-source-coverage-owner-root)
             => (path-normalize (current-directory))))))
