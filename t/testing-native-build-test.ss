;;; Native make owns cold builds, warm reuse, and dependency invalidation.
(import :gerbil/gambit
        :std/test
        (only-in :std/misc/path path-expand)
        :asp-gerbil-scheme/src/testing/build
        :asp-gerbil-scheme/src/testing/build-support)
(export testing-native-build-test)

(def (native-build-write path text)
  (call-with-output-file path (lambda (port) (display text port))))

(def (native-build-mtime path)
  (time->seconds (file-info-last-modification-time (file-info path))))

(def testing-native-build-test
  (test-suite "Testing delegates compilation to native make"
    (test-case "cold warm and changed dependency use the same native graph"
      (let* ((root (path-expand
                    (string-append "asp-native-testing-" (number->string (random-integer 1000000000)))
                    (getenv "TMPDIR" "/tmp/")))
             (artifacts (getenv "GERBIL_PATH"))
             (output (path-expand "lib/native-testing-fixture/dependency.ssi" artifacts))
             (build (testing-build root: root)))
        (create-directory root)
        (native-build-write (path-expand "gerbil.pkg" root)
                            "(package: native-testing-fixture)")
        (native-build-write (path-expand "dependency.ss" root)
                            "(export value) (def value 1)")
        (native-build-write (path-expand "entry.ss" root)
                            "(import ./dependency) (export answer) (def answer value)")
        (testing-build-compile-support-files! build ["dependency.ss" "entry.ss"])
        (check (file-exists? output) => #t)
        (let (cold (native-build-mtime output))
          (testing-build-compile-support-files! build ["dependency.ss" "entry.ss"])
          (check (native-build-mtime output) => cold)
          (thread-sleep! 1.1)
          (native-build-write (path-expand "dependency.ss" root)
                              "(export value) (def value 2)")
          (testing-build-compile-support-files! build ["dependency.ss" "entry.ss"])
          (check (> (native-build-mtime output) cold) => #t))))
    (test-case "a missing explicit target fails before execution"
      (check-exception
       (testing-build-compile-support-files!
        (testing-build root: ".") ["t/nonexistent-native-target.ss"])
       exception?))))
