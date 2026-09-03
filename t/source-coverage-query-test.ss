;;; -*- Gerbil -*-
;;; Process-local source-coverage query lifecycle tests.

(import :std/test
        (only-in :std/misc/path path-expand)
        ../src/build-api/source-coverage-query)

(export source-coverage-query-test)

(def source-coverage-query-test
  (test-suite "source coverage query lifecycle"
    (test-case "a declaration query is consumed exactly once"
      (let (source-file "build.ss")
        (asp-gerbil-scheme-register-source-coverage-query! source-file)
        (check (asp-gerbil-scheme-consume-source-coverage-query! source-file)
               => #t)
        (check (asp-gerbil-scheme-consume-source-coverage-query! source-file)
               => #f)))
    (test-case "query identity is normalized to an absolute path"
      (asp-gerbil-scheme-register-source-coverage-query! "./build.ss")
      (check (asp-gerbil-scheme-consume-source-coverage-query!
              (path-expand "build.ss"))
             => #t))))
