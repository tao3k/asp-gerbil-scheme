;;; -*- Gerbil -*-
;;; Source coverage declaration contract tests.

(import :std/test
        "../src/build-api/source-coverage"
        "../src/build-api/build-path-contract")
(export source-coverage-test)

(def source-coverage-test
  (test-suite "asp-gerbil-scheme source coverage contract"
    (test-case "source coverage files follow the build declaration"
      (configure-build-root! (current-directory))
      (asp-gerbil-scheme-source-coverage
       roots: '("src" "t")
       runtime-roots: '("src")
       exclude-directories: '("scenarios" "snapshots"))
      (let (files (asp-gerbil-scheme-source-coverage-files (current-directory)))
        (check (member "t/policy-test.ss" files) ? true)
        (check (member "t/policy/agent-source-scope-test.ss" files) ? true)
        (check (member "src/policy/gxtest.ss" files) ? true)
        (check (member "src/building/build-script-body.inc" files) ? true)
        (check (member "src/build-api/native-build.ss" files) ? true)))
    (test-case "explicit include roots do not widen the build graph"
      (let (files
            (asp-gerbil-scheme-source-coverage-files-for-roots
             (current-directory) '("src/parser" "src/utilities")))
        (check (member "src/parser/core.ss" files) ? true)
        (check (member "src/utilities/functional.ss" files) ? true)
        (check (member "src/commands/query.ss" files) => #f)))
    (test-case "source coverage declaration keeps runtime roots and excludes"
      (configure-build-root! (current-directory))
      (asp-gerbil-scheme-source-coverage
       roots: '("src" "t")
       runtime-roots: '("src")
       exclude-directories: '("fixtures"))
      (check (asp-gerbil-scheme-source-coverage-roots) => '("src" "t"))
      (check (asp-gerbil-scheme-source-coverage-runtime-roots) => '("src"))
      (check (asp-gerbil-scheme-source-coverage-exclude-directories)
             => '("fixtures")))))
