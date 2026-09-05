(import :std/test
        "../src/building/facade")

(export building-framework-test)

(def (alist-ref alist key)
  (let (entry (assq key alist))
    (and entry (cdr entry))))

(def building-framework-test
  (test-suite "asp-gerbil-scheme building framework"
    (test-case "exposes default std/make builder"
      (let (builder (default-std-builder "src"))
        (check (std-builder-name builder) => "std/make")
        (check (std-builder-stage-kind builder) => 'std/make)
        (check (std-builder-srcdir builder) => "src")
        (check (std-builder-make-options builder) => [])))
    (test-case "leaves package source concurrency to native std/make"
      (let* ((stage
              (make-package-source-stage
               "native-concurrency"
               "src"
               "asp-gerbil-scheme"
               ["core.ss"]
               #f))
             (request (package-source-stage->request stage []))
             (builder (build-profile-builder (build-request-profile request))))
        (check (std-builder-make-options builder)
               => [prefix: "asp-gerbil-scheme"])))
    (test-case "projects stage receipts for agents"
      (let* ((receipt (make-build-stage-receipt
                       "core"
                       'std/make
                       'compiled
                       "core stage"
                       'made
                       7))
             (stage-alist (build-stage-receipt->alist receipt))
             (plan-alist (build-plan-receipts->alist [receipt]))
             (summary (build-plan-receipts-summary [receipt])))
        (check (alist-ref stage-alist 'label) => "core")
        (check (alist-ref stage-alist 'kind) => 'std/make)
        (check (alist-ref stage-alist 'status) => 'compiled)
        (check (alist-ref stage-alist 'elapsed-jiffies) => 7)
        (check (alist-ref plan-alist 'version) => 1)
        (check (length (alist-ref plan-alist 'stages)) => 1)
        (check (alist-ref summary 'compiled) => 1)
        (check (alist-ref summary 'skipped) => 0)
        (check (alist-ref summary 'elapsed-jiffies) => 7)
        (check (length (alist-ref summary 'active-stages)) => 1)))
    (test-case "runs std builder spec with configured make procedure"
      (let* ((calls [])
             (builder
              (make-std-builder
               "fake-std"
               (lambda args
                 (set! calls (cons args calls))
                 'made)
               'std-builder
               "fake std/make"
               #f
               []
               (native-toolchain-default))))
        (check (std-builder-run-spec! builder ["a.ss" "b.ss"]) => 'made)
        (check calls => '((("a.ss" "b.ss"))))))
    (test-case "skips current std builder stage"
      (let* ((calls [])
             (builder
              (make-std-builder
               "fake-std"
               (lambda args
                 (set! calls (cons args calls))
                 'made)
               'std-builder
               "fake std/make"
               #f
               []
               (native-toolchain-default)))
             (stage
              (std-builder-stage
               builder
               "current"
               "current.ss"
               (lambda (stage context) #t))))
        (let (receipt (build-stage-run! stage 'context))
          (check (build-stage-receipt-status receipt) => 'skipped)
          (check calls => []))))
    (test-case "plans current std builder stages without invoking make"
      (let* ((calls [])
             (builder
              (make-std-builder
               "fake-std"
               (lambda args
                 (set! calls (cons args calls))
                 'made)
               'std-builder
               "fake std/make"
               #f
               []
               (native-toolchain-default)))
             (stages
              (std-builder-stage-plan
               builder
               [["current-a.ss"] ["current-b.ss"]]
               (lambda (spec context) #t)
               (lambda (spec) (car spec))))
             (receipts (build-plan-run! stages 'context)))
        (check (map build-stage-receipt-status receipts)
               => '(skipped skipped))
        (check calls => [])))
    (test-case "runs stale std builder stage plans in specification order"
      (let* ((calls [])
             (builder
              (make-std-builder
               "fake-std"
               (lambda args
                 (set! calls (cons args calls))
                 'made)
               'std-builder
               "fake std/make"
               #f
               []
               (native-toolchain-default)))
             (stages
              (std-builder-stage-plan
               builder
               [["first.ss"] ["second.ss"]]
               (lambda (spec context) #f)
               (lambda (spec) (car spec))))
             (receipts (build-plan-run! stages 'context)))
        (check (map build-stage-receipt-label receipts)
               => ["first.ss" "second.ss"])
        (check (map build-stage-receipt-status receipts)
               => '(compiled compiled))
        (check calls => '((("second.ss")) (("first.ss"))))))
    (test-case "runs reusable profiles through warm and stale requests"
      (let* ((calls [])
             (builder
              (make-std-builder
               "profile-std"
               (lambda args
                 (set! calls (cons args calls))
                 'made)
               'std-builder
               "profile std/make"
               #f
               []
               (native-toolchain-default)))
             (profile
              (make-std-builder-profile
               builder
               (lambda (spec) (car spec))))
             (warm-request
              (make-std-builder-request
               "warm-profile"
               profile
               [["warm-a.ss"] ["warm-b.ss"]]
               (lambda (spec context) #t)
               'warm-context))
             (stale-request
              (make-std-builder-request
               "stale-profile"
               profile
               [["stale-a.ss"] ["stale-b.ss"]]
               (lambda (spec context) #f)
               'stale-context))
             (warm-receipts (build-request-run! warm-request))
             (stale-receipts (build-request-run! stale-request))
             (projection (build-request->alist stale-request)))
    (check (map build-stage-receipt-status warm-receipts)
           => '(skipped skipped))
    (check (map build-stage-receipt-status stale-receipts)
           => '(compiled compiled))
    (check (build-profile? profile) => #t)
    (check (build-request? warm-request) => #t)
    (check (length calls) => 2)
        (check (alist-ref projection 'label) => "stale-profile")
        (check (alist-ref projection 'profile) => "profile-std")
        (check (alist-ref projection 'stage-count) => 2)))
    (test-case "runs stale std builder stage with after hook"
      (let* ((calls [])
             (after-events [])
             (builder
              (make-std-builder
               "fake-std"
               (lambda args
                 (set! calls (cons args calls))
                 'made)
               'std-builder
               "fake std/make"
               #f
               []
               (native-toolchain-default)))
             (stage
              (std-builder-stage
               builder
               "stale"
               ["stale-a.ss" "stale-b.ss"]
               (lambda (stage context) #f)
               []
               (lambda (stage context result)
                 (set! after-events (cons result after-events))))))
        (let (receipt (build-stage-run! stage 'context))
          (check (build-stage-receipt-status receipt) => 'compiled)
          (check (build-stage-receipt-result receipt) => 'made)
          (check calls => '((("stale-a.ss" "stale-b.ss"))))
          (check after-events => '(made)))))
  ))
