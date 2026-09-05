;;; -*- Gerbil -*-
;;; gerbil scheme harness CLI dispatcher policy.

(import :gerbil/gambit
        :std/test
        (only-in :asp-gerbil-scheme/src/cli-launcher provider-command-line-args main)
        (only-in :asp-gerbil-scheme/src/cli-release-linker release-command-dispatch)
        (only-in :asp-gerbil-scheme/src/protocol/command-catalog
                 provider-command-names
                 provider-dynamic-command-dispatch)
        )
(export cli-test)

;; : TestSuite
(def cli-test
  (test-suite "gerbil scheme harness CLI"
    (test-case "provider argv keeps direct subcommands"
      (check (provider-command-line-args
              ["search" "owner" "src/main.ss"])
             => ["search" "owner" "src/main.ss"]))
    (test-case "provider argv strips gxi launcher frames"
      (check (provider-command-line-args
              ["gxi" "src/cli.ss" "query" "src/main.ss"])
             => ["query" "src/main.ss"]))
    (test-case "provider argv strips generated binary frames"
      (check (provider-command-line-args
              ["asp-gerbil-scheme" "fmt" "--check" "/tmp/project"])
             => ["fmt" "--check" "/tmp/project"]))
    (test-case "provider argv preserves help requests"
      (check (provider-command-line-args
              ["asp-gerbil-scheme" "--help"])
             => ["--help"]))
    (test-case "provider argv strips no-argument launcher frames"
      (check (provider-command-line-args
              ["asp-gerbil-scheme"])
             => []))
    (test-case "provider argv preserves unknown commands"
      (check (provider-command-line-args
              ["gxi" "src/cli.ss" "bogus"])
             => ["bogus"]))
    (test-case "provider argv keeps formatter command"
      (check (provider-command-line-args
              ["asp-gerbil-scheme" "fmt" "--check" "."])
             => ["fmt" "--check" "."]))
    (test-case "command catalog owns dynamic and release command names"
      (check (member "serve" provider-command-names) => #f)
      (check (map car provider-dynamic-command-dispatch)
             => provider-command-names)
      (check (map car release-command-dispatch)
             => provider-command-names)
      (check (andmap (lambda (entry) (procedure? (cadr entry)))
                     release-command-dispatch)
             => #t))
    ))
