;;; -*- Gerbil -*-
;;; Native gxtest failure used to prove batch exit-status propagation.
(import :std/test)
(export failure-test)

(def failure-test
  (test-suite "upstream failure exit"
    (test-case "fails intentionally"
      (check 1 => 2))))
