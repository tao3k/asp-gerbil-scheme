;;; -*- Gerbil -*-
(import :gerbil/runtime/gambit)

(export upstream-gxtest-files
        upstream-gxtest-main)

(def +upstream-gxtest-root+
  "t/scenarios/policy/upstream-gxtest-delegation/input")

(def upstream-gxtest-files
  ["t/alpha-test.ss" "t/beta-test.ss"])

(def (upstream-gxtest-main args)
  (display "manual gxtest file selection: ")
  (write upstream-gxtest-files)
  (newline)
  #t)
