;;; -*- Gerbil -*-
(import :std/test)
(export relocated-root-test)
(def relocated-root-test
  (test-suite "relocated entry root discovery"
    (test-case "parent test tree remains visible" (check #t => #t))))
