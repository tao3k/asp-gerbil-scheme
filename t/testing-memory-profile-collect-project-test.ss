;;; -*- Gerbil -*-

(import :std/test
        :asp-gerbil-scheme/src/testing/gxtest-execution)

(export testing-memory-profile-collect-project-test)

(def testing-memory-profile-collect-project-test
  (test-suite "gxtest memory profile project index"
    (test-case "bounds repeated project-index materialization"
      (let (result
            (run-gxtest-file/subprocess
             "t/memory-profile-collect-project-exception.ss"))
        (check (gxtest-result-status result) => 0)))))
