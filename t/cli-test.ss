;;; -*- Gerbil -*-
;;; gerbil scheme harness CLI dispatcher policy.

(import :gerbil/gambit
        :std/test
        (only-in :std/srfi/13 string-contains)
        (only-in :gslph/src/cli-launcher provider-command-line-args main)
        (only-in :gslph/src/commands/project-resolution
                 project-resolution-request->response)
        (only-in :gslph/src/cli-release-linker release-command-dispatch)
        (only-in :gslph/src/protocol/command-catalog
                 provider-command-names
                 provider-dynamic-command-dispatch)
        (only-in :std/sugar hash hash-key?)
        (only-in "./unit/parser/parser-test-part8-support"
                 ensure-dir
                 write-text))
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
              ["gslph" "fmt" "--check" "/tmp/project"])
             => ["fmt" "--check" "/tmp/project"]))
    (test-case "provider argv preserves help requests"
      (check (provider-command-line-args
              ["gslph" "--help"])
             => ["--help"]))
    (test-case "provider argv strips no-argument launcher frames"
      (check (provider-command-line-args
              ["gslph"])
             => []))
    (test-case "provider argv preserves unknown commands"
      (check (provider-command-line-args
              ["gxi" "src/cli.ss" "bogus"])
             => ["bogus"]))
    (test-case "provider argv keeps formatter command"
      (check (provider-command-line-args
              ["gslph" "fmt" "--check" "."])
             => ["fmt" "--check" "."]))
    (test-case "command catalog owns dynamic and release command names"
      (check (map car provider-dynamic-command-dispatch)
             => provider-command-names)
      (check (map car release-command-dispatch)
             => provider-command-names)
      (check (andmap (lambda (entry) (procedure? (cadr entry)))
                     release-command-dispatch)
             => #t))
    (test-case "ProjectResolution derives root scope from package build semantics"
      (let* ((root ".run/cli-project-resolution")
             (source-root (string-append root "/src")))
        (ensure-dir ".run")
        (ensure-dir root)
        (ensure-dir source-root)
        (write-text (string-append root "/gerbil.pkg")
                    "(package: sample/project-resolution)\n")
        (write-text (string-append root "/build.ss")
                    "(defbuild-script (all-gerbil-modules))\n")
        (write-text (string-append source-root "/main.ss")
                    "(def main-value 1)\n")
        (let* ((response
                (with-project-resolution-root
                 root
                 (lambda ()
                   (project-resolution-request->response
                    (project-resolution-test-request)))))
               (scope (hash-ref response "scope"))
               (graph (hash-ref scope "packageGraph"))
               (packages (hash-ref graph "packages"))
               (scopes (hash-ref scope "sourceScopes")))
          (check (hash-ref response "state") => "resolved")
          (check (hash-key? response "resolution") => #f)
          (check (hash-ref scope "completeness") => "exact")
          (check (length packages) => 1)
          (check (length scopes) => 1)
          (check (hash-ref (car scopes) "roots") => ["."])
          (check (hash-ref (car scopes) "explicitPaths") => ["."])
          (check (hash-ref (hash-ref scope "metrics") "fullWorkspaceReads")
                 => 0))))
    (test-case "ProjectResolution does not promote a nested package entry"
      (let* ((root ".run/cli-project-resolution-nested")
             (nested (string-append root "/packages/nested")))
        (ensure-dir root)
        (ensure-dir (string-append root "/packages"))
        (ensure-dir nested)
        (write-text (string-append nested "/gerbil.pkg")
                    "(package: sample/nested)\n")
        (check
         (with-catch
          (lambda (error) #t)
          (lambda ()
            (with-project-resolution-root
             root
             (lambda ()
               (project-resolution-request->response
                (project-resolution-test-request-with-candidates
                 ["packages/nested/gerbil.pkg"]))))
            #f))
         => #t)))
    ))

(def (project-resolution-test-request)
  (project-resolution-test-request-with-candidates
   ["gerbil.pkg" "build.ss" "src/main.ss"]))

(def (project-resolution-test-request-with-candidates candidates)
  (hash
   ("schemaId" "agent.semantic-protocols.provider-project-resolution-request")
   ("schemaVersion" "1")
   ("languageId" "gerbil-scheme")
   ("providerId" "gerbil-scheme-harness")
   ("candidateBase" ".")
   ("candidateGeneration"
    (hash
     ("algorithm" "blake3-path-set-v1")
     ("digest" (string-append "blake3:" (make-string 64 #\a)))
     ("authorities" ["asp-workspace-admission"])))
   ("collectionScope" (hash ("kind" "complete-generation")))
   ("candidatePaths" candidates)
   ("policyExclusions" [])))

(def (with-project-resolution-root root thunk)
  (let (previous (current-directory))
    (dynamic-wind
     (lambda () (current-directory root))
     thunk
     (lambda () (current-directory previous)))))
