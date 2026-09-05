(import :std/test
        :asp-gerbil-scheme/src/building/facade
        :asp-gerbil-scheme/src/building/declarative
        :asp-gerbil-scheme/src/testing/model
        :asp-gerbil-scheme/src/testing/building)

(export building-declarative-test)

(define-std-build declared-build-request
  label: "declared-build"
  source: #f
  make-options: [optimize: #f parallelize: 3]
  label-of: (lambda (spec) (car spec))
  after: (lambda (_stage _context _result) #!void)
  stage-specs: [["declared-a.ss"] ["declared-b.ss"]]
  current?: (lambda (_spec _context) #t)
  context: '((environment . caller-owned)))

(define-build-request expression-declared-request
  label: "expression-declared"
  profile: (build-request-profile declared-build-request)
  stage-specs: []
  current?: (lambda (_spec _context) #t)
  context: 'expression-declared-context)

(define-build-performance-project declared-performance-project
  request: declared-build-request
  fixture-path: "t"
  name: "declarative-building-project"
  suite-name: "declarative-building-suite"
  suite-names: #f
  case-names: #f
  roots: ["t"]
  gates: [])

(define-build-performance-project declared-matrix-project
  request: declared-build-request
  fixture-path: "t"
  name: "declarative-building-matrix"
  suite-name: "unused-default-suite"
  suite-names: ["suite-a" "suite-b"]
  case-names: ["plan-a" "plan-b"]
  roots: ["t"]
  gates: [])

(def expression-performance-project
  (build-performance-project
   request: declared-build-request
   fixture-path: "t"
   name: "expression-building-project"
   suite-name: "expression-building-suite"
   suite-names: #f
   case-names: #f
   roots: ["t"]
   gates: []))

(def building-declarative-test
  (test-suite "asp gerbil-scheme declarative building API"
    (test-case "defines a caller-configured std build request"
      (check (build-request? declared-build-request) => #t)
      (check (build-request-label declared-build-request) => "declared-build")
      (check (build-profile-name
              (build-request-profile declared-build-request))
             => "std/make")
      (check (length (build-request-stage-specs declared-build-request)) => 2)
      (check (build-request-context declared-build-request)
             => '((environment . caller-owned))))
    (test-case "defines a request through the generic declaration macro"
      (check (build-request? expression-declared-request) => #t)
      (check (build-request-label expression-declared-request)
             => "expression-declared"))
    (test-case "uses the expression macro inside a caller scope"
      (let (request
            (std-build
             label: "expression-build"
             source: #f
             make-options: []
             label-of: (lambda (spec) (car spec))
             after: (lambda (_stage _context _result) #!void)
             stage-specs: [["expression.ss"]]
             current?: (lambda (_spec _context) #t)
             context: 'expression-context))
        (check (build-request? request) => #t)
        (check (map build-stage-receipt-status
                    (build-request-run! request))
               => '(skipped))))
    (test-case "projects a declared build into the testing framework"
      (let* ((suite (car (testing-project-suites
                          declared-performance-project)))
             (case (car (testing-performance-suite-cases suite)))
             (plan ((testing-performance-case-runner case))))
        (check (testing-object-kind declared-performance-project)
               => 'testing-project)
        (check (testing-performance-case-fixture-path case) => "t")
        (check (build-request-stage-plan-valid? plan) => #t)
        (check (length plan) => 2)))
    (test-case "projects a build through the expression macro"
      (check (testing-object-kind expression-performance-project)
             => 'testing-project))
    (test-case "configures a suite and case matrix without hardcoded framework state"
      (let (suites (testing-project-suites declared-matrix-project))
        (check (length suites) => 2)
        (check (map testing-suite-name suites) => ["suite-a" "suite-b"])
        (check (map (lambda (suite)
                      (length (testing-performance-suite-cases suite)))
                    suites)
               => [2 2])))))
