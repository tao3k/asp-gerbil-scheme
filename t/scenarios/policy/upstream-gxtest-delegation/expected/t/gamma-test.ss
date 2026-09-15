;;; -*- Gerbil -*-
(import :std/test)

(export gamma-test)

(def gamma-test
  (test-suite "upstream gamma"
    (test-case "ordinary native suite"
      (check (string-append "g" "amma") => "gamma"))))
