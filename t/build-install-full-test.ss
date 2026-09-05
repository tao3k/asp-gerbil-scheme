;;; -*- Gerbil -*-
;;; Full build/install path side-effect tests.

(import :gerbil/gambit
        :std/test
        (only-in :std/misc/path path-expand)
        "../src/build-api/build-path-contract")

(export build-install-full-test)

(def build-install-full-test
  (test-suite "asp gerbil-scheme build install path full contract"
    (test-case "clean removes package-local development launcher artifacts"
      (configure-build-root! (current-directory))
      (unless (file-exists? ".bin")
        (create-directory ".bin"))
      (let ((binpath (dev-launcher-binpath))
            (artifact (path-expand ".bin/asp-gerbil-scheme__exe.c" (current-directory))))
        (call-with-output-file binpath
          (lambda (out) (display "test launcher" out)))
        (call-with-output-file artifact
          (lambda (out) (display "test artifact" out)))
        (check (file-exists? binpath) => #t)
        (check (file-exists? artifact) => #t)
        (clean-target)
        (check (file-exists? binpath) => #f)
        (check (file-exists? artifact) => #f)))))
