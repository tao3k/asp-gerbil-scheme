;;; Boundary: Testing projects BuildRequest plans into performance objects without a reverse dependency from Building.

(import (only-in ./model performance-case performance-suite testing-project)
        (only-in ../building/facade
                 build-request-stage-plan
                 build-request->alist
                 build-stage?))

(export build-request-stage-plan-runner
        build-request-stage-plan-valid?
        make-build-request-performance-case
        make-build-request-performance-suite
        make-build-request-performance-project
        build-performance-project
        define-build-performance-project)

;;; Testing owns this projection boundary. It imports Building, but the
;;; Building library never imports Testing or materializes Testing objects.

;; : (forall (stage) (-> BuildRequest (-> (List stage))))
;; build-request-stage-plan-runner
;;   : (-> BuildRequest (-> (List BuildStage)))
;; | doc m%
;; Produce a pure runner that exposes a request's stage plan to Testing.
;; # Examples
;; ```scheme
;; (build-request-stage-plan-runner request)
;; => runner
;; ```
;; Result: a zero-argument runner that returns the request stage plan.
;;; Boundary: the runner exposes planning data while Builder owns side-effecting execution.
(def (build-request-stage-plan-runner request)
  (lambda ()
    (build-request-stage-plan request)))

;; : (forall (stage) (-> (List stage) Boolean))
;; build-request-stage-plan-valid?
;;   : (-> (List BuildStage) Boolean)
;; | doc m%
;; Validate the result shape expected from a stage-plan performance runner.
;; # Examples
;; ```scheme
;; (build-request-stage-plan-valid? [])
;; => #t
;; ```
;; Result: #t only when every value is a BuildStage.
;;; Boundary: validation accepts planning values only and never invokes Builder work.
(def (build-request-stage-plan-valid? value)
  (and (list? value)
       (andmap build-stage? value)))

;; : (forall (detail) (-> BuildRequest Path String (List detail) PerformanceCase))
;; make-build-request-performance-case
;;   : (-> BuildRequest Path String (List PerformanceDetail) PerformanceCase)
;; | doc m%
;; Project one BuildRequest into a Testing performance case with a receipt projection.
;; # Examples
;; ```scheme
;; (make-build-request-performance-case request "t")
;; => performance-case
;; ```
;; Result: one Testing performance case with a projected build receipt.
;;; Boundary: diagnostics receive request data without a reverse Testing dependency in Builder.
(def (make-build-request-performance-case request
                                          fixture-path
                                          name: (name "build-request-stage-plan")
                                          details: (details []))
  (performance-case
   name: name
   fixture-path: fixture-path
   runner: (build-request-stage-plan-runner request)
   validator: build-request-stage-plan-valid?
   details: (append
             `((buildRequest . ,(build-request->alist request)))
             details)))

;; : (forall (case) (-> BuildRequest Path String (List case) PerformanceSuite))
;; make-build-request-performance-suite
;;   : (-> BuildRequest Path String (List PerformanceCaseName) PerformanceSuite)
;; | doc m%
;; Group the request projection into a Testing performance suite.
;; # Examples
;; ```scheme
;; (make-build-request-performance-suite request "t" roots: ["t"] gates: [])
;; => performance-suite
;; ```
;; Result: a Testing suite whose cases share one BuildRequest projection.
;;; Boundary: suite expansion creates Testing cases while gates cannot change Builder configuration.
(def (make-build-request-performance-suite request
                                           fixture-path
                                           name: (name "building-performance")
                                           case-name: (case-name "build-request-stage-plan")
                                           case-names: (case-names #f)
                                           roots: (roots [])
                                           gates: (gates []))
  (performance-suite
   name: name
   roots: roots
   cases: (map (lambda (name)
                 (make-build-request-performance-case
                  request
                  fixture-path
                  name: name))
               (or case-names [case-name]))
   gates: gates))

;; : (forall (suite) (-> BuildRequest Path String (List suite) TestingProject))
;; make-build-request-performance-project
;;   : (-> BuildRequest Path String (List PerformanceSuiteName) TestingProject)
;; | doc m%
;; Create a complete Testing project for one caller-provided BuildRequest.
;; # Examples
;; ```scheme
;; (make-build-request-performance-project request "t" roots: ["t"] gates: [])
;; => testing-project
;; ```
;; Result: a TestingProject containing one or more performance suites.
;;; Boundary: the project is a Testing value and preserves the caller's BuildRequest unchanged.
(def (make-build-request-performance-project request
                                             fixture-path
                                             name: (name "building-performance-project")
                                             suite-name: (suite-name "building-performance")
                                             suite-names: (suite-names #f)
                                             case-names: (case-names #f)
                                             roots: (roots [])
                                             gates: (gates []))
  (testing-project
   name: name
   suites: (map (lambda (name)
                  (make-build-request-performance-suite
                   request
                   fixture-path
                   name: name
                   case-names: case-names
                   roots: roots
                   gates: gates))
                (or suite-names [suite-name]))
   roots: roots))

;; : (forall (suite) (-> BuildRequest Path String (List suite) TestingProject))
;; build-performance-project
;;   : (-> BuildRequest Path String (List PerformanceSuiteName) TestingProject)
;; | doc m%
;; Lower a Testing projection declaration to a project expression.
;; # Examples
;; ```scheme
;; (build-performance-project request: request fixture-path: "t" name: "build"
;;   suite-name: "suite" roots: ["t"] gates: [])
;; => testing-project
;; ```
;; Result: an expression-level TestingProject projection.
;;; Boundary: macro expansion projects a ready BuildRequest without altering Builder policy.
(defrules build-performance-project ()
  ((_ request: request
      fixture-path: fixture-path
      name: name
      suite-name: suite-name
      suite-names: suite-names
      case-names: case-names
      roots: roots
      gates: gates)
   (make-build-request-performance-project
    request
    fixture-path
    name: name
    suite-name: suite-name
    suite-names: suite-names
    case-names: case-names
    roots: roots
    gates: gates)))

;; : (forall (suite) (-> Identifier BuildRequest Path String (List suite) TestingProject))
;; define-build-performance-project
;;   : (-> Identifier BuildRequest Path String (List PerformanceSuiteName) TestingProject)
;; | doc m%
;; Bind a Testing projection for a downstream build or benchmark declaration.
;; # Examples
;; ```scheme
;; (define-build-performance-project project request: request fixture-path: "t"
;;   name: "build" suite-name: "suite" roots: ["t"] gates: [])
;; => project
;; ```
;; Result: a binding that names the same TestingProject shape as the expression macro.
;;; Boundary: binding delegates through build-performance-project so both forms remain equivalent.
(defrules define-build-performance-project ()
  ((_ binding arguments ...)
   (def binding
     (build-performance-project arguments ...))))
