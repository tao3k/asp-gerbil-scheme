(import :std/test
        :gerbil/gambit
        "../src/building/facade")

(export building-performance-test)

(def (cpu-elapsed-ms thunk)
  (let (started (##process-statistics))
    (thunk)
    (let (finished (##process-statistics))
      (* 1000.0
         (+ (- (f64vector-ref finished 0) (f64vector-ref started 0))
            (- (f64vector-ref finished 1) (f64vector-ref started 1)))))))

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
               []))
             (stage
              (std-builder-stage
               builder
               "current"
               "current.ss"
               (lambda (stage context) #t)))
             (elapsed
              (cpu-elapsed-ms
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
               []))
             (stage
              (std-builder-stage
               builder
               "stale"
               "stale.ss"
               (lambda (stage context) #f)))
             (elapsed
              (cpu-elapsed-ms
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
               []))
             (stage-specs
              [["a.ss"] ["b.ss"] ["c.ss"] ["d.ss"]
               ["e.ss"] ["f.ss"] ["g.ss"] ["h.ss"]])
             (elapsed
              (cpu-elapsed-ms
               (lambda ()
                 (repeat 500
                   (lambda ()
                     (std-builder-stage-plan
                      builder
                      stage-specs
                      (lambda (spec context) #t)
                      (lambda (spec) (car spec)))))))))
        (check call-count => 0)
        (check (< elapsed 300.0) => #t)))))
