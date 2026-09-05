;;; -*- Gerbil -*-
;;; CLI agent command contracts.

(import :gerbil/gambit
        :std/test
        (only-in :std/srfi/13 string-contains)
        (only-in :asp-gerbil-scheme/src/commands/agent agent-main))
(export cli-agent-test)

;; : TestSuite
(def cli-agent-test
  (test-suite "gerbil scheme harness CLI agent command"
    (test-case "agent guide forwards section flags"
      (let (status #f)
        (let (output
              (with-output-to-string
                (lambda ()
                  (set! status (agent-main ["guide" "." "--poo"])))))
          (check status => 0)
          (check (and (string-contains output "poo-prototype-fixed-point") #t)
                 => #t)
          (check (and (string-contains output "GERBIL-SCHEME-AGENT-POLICY-026") #t)
                 => #t))))))
