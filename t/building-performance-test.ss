(import :std/test
        :gerbil/gambit
        "../src/building/facade"
        (only-in :asp-gerbil-scheme/src/testing/execution-profile
                 declare-gxtest-serial)
        (only-in "../src/build-api/package-native-plan"
                 asp-gerbil-scheme-package-api-stage-specs))

(export building-performance-test)

(declare-gxtest-serial timing-sensitive-building)

(def (elapsed-ms thunk)
  (let (started (time->seconds (current-time)))
    (thunk)
    (* 1000.0 (- (time->seconds (current-time)) started))))

(def (repeat count thunk)
  (let loop ((remaining count))
    (unless (= remaining 0)
      (thunk)
      (loop (- remaining 1)))))

(def building-performance-test
  (test-suite "asp-gerbil-scheme building performance"
    (test-case "skips current stage within framework budget"
      (let* ((call-count 0)
             (builder
              (make-std-builder
               "performance-std"
               (lambda args
                 (set! call-count (+ call-count 1))
                 'made)
               'std-builder
               "performance std/make"
               #f
               []
               (native-toolchain-default)))
             (stage
              (std-builder-stage
               builder
               "current"
               "current.ss"
               (lambda (stage context) #t)))
             (elapsed
              (elapsed-ms
               (lambda ()
                 (repeat 2000
                   (lambda ()
                     (build-stage-run! stage 'context)))))))
        (check call-count => 0)
        (check (< elapsed 200.0) => #t)))
    (test-case "runs stale stage within framework budget"
      (let* ((call-count 0)
             (builder
              (make-std-builder
               "performance-std"
               (lambda args
                 (set! call-count (+ call-count 1))
                 'made)
               'std-builder
               "performance std/make"
               #f
               []
               (native-toolchain-default)))
             (stage
              (std-builder-stage
               builder
               "stale"
               "stale.ss"
               (lambda (stage context) #f)))
             (elapsed
              (elapsed-ms
               (lambda ()
                 (repeat 500
                   (lambda ()
                     (build-stage-run! stage 'context)))))))
        (check call-count => 500)
        (check (< elapsed 300.0) => #t)))
    (test-case "constructs std builder stage plans within framework budget"
      (let* ((call-count 0)
             (builder
              (make-std-builder
               "performance-std"
               (lambda args
                 (set! call-count (+ call-count 1))
                 'made)
               'std-builder
               "performance std/make"
               #f
               []
               (native-toolchain-default)))
             (stage-specs
              [["a.ss"] ["b.ss"] ["c.ss"] ["d.ss"]
               ["e.ss"] ["f.ss"] ["g.ss"] ["h.ss"]])
             (elapsed
              (elapsed-ms
               (lambda ()
                 (repeat 500
                   (lambda ()
                     (std-builder-stage-plan
                      builder
                      stage-specs
                      (lambda (spec context) #t)
                      (lambda (spec) (car spec)))))))))
        (check call-count => 0)
        (check (< elapsed 300.0) => #t)))
    (test-case "constructs package stage plan within budget"
      (let (elapsed
            (elapsed-ms
             (lambda ()
               (repeat 500
                 (lambda ()
                   (asp-gerbil-scheme-package-api-stage-specs))))))
        (check (< elapsed 300.0) => #t)))))
