(import :std/test
        "../src/build-api/framework")

(export build-api-framework-test)

(def (alist-ref alist key)
  (let (entry (assq key alist))
    (and entry (cdr entry))))

(def build-api-framework-test
  (test-suite "asp-gerbil-scheme build api framework"
    (test-case "skips current stage"
      (let* ((events [])
             (stage
              (make-build-stage
               "current-stage"
               'unit
               '(spec)
               (lambda (stage context) #t)
               (lambda (stage context)
                 (set! events (cons 'run events))
                 'ran)
               (lambda (stage context result)
                 (set! events (cons 'after events)))
               "current stage")))
        (let (receipt (build-stage-run! stage 'context))
          (check (build-stage-receipt-status receipt) => 'skipped)
          (check events => []))))
    (test-case "runs stale stage with after hook"
      (let* ((events [])
             (stage
              (make-build-stage
               "stale-stage"
               'unit
               '(spec)
               (lambda (stage context) #f)
               (lambda (stage context)
                 (set! events (cons 'run events))
                 'ran)
               (lambda (stage context result)
                 (set! events (cons result events)))
               "stale stage")))
        (let (receipt (build-stage-run! stage 'context))
          (check (build-stage-receipt-status receipt) => 'compiled)
          (check (build-stage-receipt-result receipt) => 'ran)
          (check events => '(ran run)))))
    (test-case "runs build plan in stage order"
      (let* ((events [])
             (first
              (make-build-stage
               "first"
               'unit
               '(first)
               (lambda (stage context) #f)
               (lambda (stage context)
                 (set! events (cons 'first events))
                 'first-result)
               (lambda (stage context result) #!void)
               "first stage"))
             (second
              (make-build-stage
               "second"
               'unit
               '(second)
               (lambda (stage context) #f)
               (lambda (stage context)
                 (set! events (cons 'second events))
                 'second-result)
               (lambda (stage context result) #!void)
               "second stage")))
        (let (receipts (build-plan-run! [first second] 'context))
          (check (map build-stage-receipt-label receipts) => ["first" "second"])
          (check events => '(second first)))))
    (test-case "projects receipts through build-api facade"
      (let* ((receipt (make-build-stage-receipt
                       "facade"
                       'unit
                       'skipped
                       "facade projection"
                       #f
                       3))
             (projection (build-plan-receipts->alist [receipt])))
        (check (alist-ref projection 'version) => 1)
        (check (alist-ref (car (alist-ref projection 'stages)) 'label)
               => "facade")))))
