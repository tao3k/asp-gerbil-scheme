;;; -*- Gerbil -*-
;;; Executable contracts for POO macro admission independent of package metadata.

(import :gerbil/gambit
        :std/test
        (only-in :std/misc/process run-process)
        (only-in :clan/poo/object .cc)
        :asp-gerbil-scheme/src/macro-governance/facade
        :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/scenario/policy
        :asp-gerbil-scheme/src/testing/memory-profile
        :asp-gerbil-scheme/src/types/facade)

(export macro-governance-framework-policy-test)

(declare-gxtest-memory-exception
 '((maxHeapMiB . 512)))

(def (macro-governance-reset-root root)
  (when (file-exists? root)
    (void (run-process ["rm" "-rf" root] stderr-redirection: #t))))

(def (macro-governance-ensure-directory path)
  (with-catch (lambda (_) #f) (lambda () (create-directory path))))

(def (macro-governance-write-text path text)
  (when (file-exists? path) (delete-file path))
  (call-with-output-file path (lambda (port) (display text port))))

;; : (-> String String String Unit)
(def (write-macro-governance-project root macro-source test-source)
  (let ((source-dir (string-append root "/src"))
        (test-dir (string-append root "/t")))
    (macro-governance-reset-root root)
    (macro-governance-ensure-directory ".run")
    (macro-governance-ensure-directory root)
    (macro-governance-ensure-directory source-dir)
    (macro-governance-ensure-directory test-dir)
    (macro-governance-write-text
     (string-append root "/gerbil.pkg")
     "(package: sample/macro-governance)\n")
    (macro-governance-write-text
     (string-append source-dir "/core.ss") macro-source)
    (macro-governance-write-text
     (string-append test-dir "/core-test.ss") test-source)))

;; : TestSuite
(def macro-governance-framework-policy-test
  (test-suite "Gerbil macro governance framework"
    (test-case "strict profile is an immutable POO policy value"
      (check (macro-governance-profile-name
              asp-strict-macro-governance-profile)
             => 'asp-strict-v1)
      (check (macro-governance-profile-require-hygiene?
              asp-strict-macro-governance-profile)
             => #t)
      (let (narrower
            (.cc asp-strict-macro-governance-profile
                 'max-pattern-count
                 1))
        (check (macro-governance-profile-max-pattern-count narrower) => 1)
        (check (macro-governance-profile-max-pattern-count
                asp-strict-macro-governance-profile)
               => 64)))
    (test-case "admission accepts a bounded hygienic macro with executable witness"
      (let (root ".run/macro-governance-admitted")
        (write-macro-governance-project
         root
         ";;; -*- Gerbil -*-\n(package: sample/macro-governance)\n(export define-value)\n(defrules define-value () ((_ name value) (def name value)))\n"
         ";;; -*- Gerbil -*-\n(import :std/test ../src/core)\n(def core-test (test-suite \"core\" (test-case \"expands\" (define-value answer 42) (check answer => 42))))\n")
        (let (receipt (macro-governance-admit (collect-project root)))
          (check (macro-governance-receipt-schema-version receipt) => "1")
          (check (macro-governance-receipt-status receipt) => 'admitted)
          (check (macro-governance-receipt-macro-count receipt) => 1)
          (check (macro-governance-receipt-rejected-count receipt) => 0))))
    (test-case "admission rejects an unhygienic transformer with a typed reason"
      (let (root ".run/macro-governance-unhygienic")
        (write-macro-governance-project
         root
         ";;; -*- Gerbil -*-\n(package: sample/macro-governance)\n(export define-value)\n(defsyntax define-value (lambda (stx) stx))\n"
         ";;; -*- Gerbil -*-\n(import :std/test ../src/core)\n(def core-test (test-suite \"core\" (test-case \"mentions transformer\" (check #t => #t))))\n")
        (let* ((receipt (macro-governance-admit (collect-project root)))
               (decision (car (macro-governance-receipt-decisions receipt))))
          (check (macro-governance-receipt-status receipt) => 'rejected)
          (check (macro-governance-receipt-rejected-count receipt) => 1)
          (check (member 'hygiene-required
                         (macro-governance-decision-reason-kinds decision))
                 => '(hygiene-required)))))
    (test-case "one compiled profile preserves every rejection reason"
      (let ((root ".run/macro-governance-profile-reasons")
            (profile
             (.cc asp-strict-macro-governance-profile
                  'allowed-phases
                  []
                  'max-pattern-count
                  0)))
        (write-macro-governance-project
         root
         ";;; -*- Gerbil -*-\n(package: sample/macro-governance)\n(export define-value)\n(defrules define-value () ((_ name value) (def name value)))\n"
         ";;; -*- Gerbil -*-\n(import :std/test ../src/core)\n(def core-test (test-suite \"core\" (test-case \"expands\" (define-value answer 42) (check answer => 42))))\n")
        (let* ((receipt
                (macro-governance-admit
                 (collect-project root)
                 profile: profile))
               (decision
                (car (macro-governance-receipt-decisions receipt)))
               (reasons
                (macro-governance-decision-reason-kinds decision)))
          (check (macro-governance-receipt-status receipt) => 'rejected)
          (check (member 'phase-not-admitted reasons)
                 => '(phase-not-admitted pattern-budget-exceeded))
          (check (member 'pattern-budget-exceeded reasons)
                 => '(pattern-budget-exceeded)))))
    (test-case "package policy cannot enable disable or satisfy macro admission"
      (let (root ".run/macro-governance-package-ignored")
        (write-macro-governance-project
         root
         "(export define-value)\n(defsyntax define-value (lambda (stx) stx))\n"
         "(import :std/test)\n(def core-test (test-suite \"no invocation\" (test-case \"asserts only\" (check #t => #t))))\n")
        (let (baseline (macro-governance-receipt-json
                         (macro-governance-admit (collect-project root))))
          (macro-governance-write-text
           (string-append root "/gerbil.pkg")
           "(package: sample/macro-governance policy: ((agent-policy disabled-rules: (\"GERBIL-SCHEME-MACRO-GOVERNANCE-001\") explanation: \"legacy exception\") (macro-governance witnesses: ((\"define-value\" \"t/core-test.ss\")))))\n")
          (check (source-file-parse-error (parse-source-file root "gerbil.pkg")) => #f)
          (check (macro-governance-receipt-json
                   (macro-governance-admit (collect-project root))) => baseline)
          (delete-file (string-append root "/gerbil.pkg"))
          (check (macro-governance-receipt-json
                   (macro-governance-admit (collect-project root))) => baseline)
          (check (hash-get baseline 'status) => "rejected"))))
    (test-case "scenario closes an unhygienic macro admission finding"
      (let* ((scenario
              (make-policy-scenario
               "macro-governance-admission"
               "t/scenarios/policy/macro-governance-admission"))
             (timing (policy-scenario-run/timed scenario))
             (result (hash-get timing 'result))
             (benchmark-contract (hash-get timing 'benchmarkContract))
             (before-matching
              (policy-scenario-findings
               result
               'before
               "GERBIL-SCHEME-MACRO-GOVERNANCE-001"))
             (after-matching
              (policy-scenario-findings
               result
               'after
               "GERBIL-SCHEME-MACRO-GOVERNANCE-001"))
             (before-macro
              (policy-scenario-required-first-macro-fact result 'before))
             (after-macro
              (policy-scenario-required-first-macro-fact result 'after))
             (finding (car before-matching))
             (details (type-finding-details finding)))
        (check (hash-get timing 'performanceStatus) => "pass")
        (check (hash-get benchmark-contract 'feature)
               => "macro-governance-admission")
        (check (hash-get benchmark-contract 'rule)
               => "GERBIL-SCHEME-MACRO-GOVERNANCE-001")
        (check (length before-matching) => 1)
        (check after-matching => [])
        (check (macro-fact-hygienic before-macro) => #f)
        (check (macro-fact-hygienic after-macro) => #t)
        (check (hash-get details 'kind) => "macro-governance-admission")
        (check (hash-get details 'reasonKinds) => ["hygiene-required"])))))
