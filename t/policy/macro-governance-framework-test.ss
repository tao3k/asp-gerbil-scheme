;;; -*- Gerbil -*-
;;; Executable contracts for package macro admission and typed receipts.

(import :gerbil/gambit
        :std/test
        (only-in :clan/poo/object .cc)
        :asp-gerbil-scheme/src/macro-governance/facade
        :asp-gerbil-scheme/src/parser/facade
        :asp-gerbil-scheme/src/scenario/policy
        :asp-gerbil-scheme/src/types/facade
        "./fixtures")

(export macro-governance-framework-policy-test)

;; : (-> String String String Unit)
(def (write-macro-governance-project root macro-source test-source)
  (let ((source-dir (string-append root "/src"))
        (test-dir (string-append root "/t")))
    (reset-fixture-root root)
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir source-dir)
    (ensure-dir test-dir)
    (write-text
     (string-append root "/gerbil.pkg")
     (string-append
      "(package: sample/macro-governance\n"
      " policy: ((source-scope roots: (\"src\") runtime-roots: (\"src\") exclude-directories: ())\n"
      "          (macro-governance\n"
      "           explanation: \"Every governed macro has executable source evidence.\"\n"
      "           witnesses: ((\"define-value\" \"t/core-test.ss\")))))\n"))
    (write-text (string-append source-dir "/core.ss") macro-source)
    (write-text (string-append test-dir "/core-test.ss") test-source)))

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
