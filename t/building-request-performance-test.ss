(export building-request-performance-test)

(import :std/test
        :gerbil/gambit
        :asp-gerbil-scheme/src/building/facade)

(def (cpu-elapsed-ms thunk)
  (let (start (##process-statistics))
    (thunk)
    (let (end (##process-statistics))
      (* 1000.
         (+ (- (f64vector-ref end 0) (f64vector-ref start 0))
            (- (f64vector-ref end 1) (f64vector-ref start 1)))))))

(def building-request-performance-test
  (test-suite
   "asp-gerbil-scheme building request performance"
   (test-case "constructs and projects reusable requests within framework budget"
     (let* ((make-calls 0)
            (builder
             (make-std-builder
              "request-profile"
              (lambda args
                (set! make-calls (+ make-calls 1))
                'made)
              'std-builder
              "request profile test builder"
              #f
              []))
            (stage-specs
             [["alpha.ss"] ["beta.ss"] ["gamma.ss"] ["delta.ss"]])
            (elapsed
             (cpu-elapsed-ms
              (lambda ()
                (let loop ((remaining 5000))
                  (if (> remaining 0)
                    (let* ((profile (make-std-builder-profile builder))
                           (request
                            (make-std-builder-request
                             "request-profile"
                             profile
                             stage-specs
                             (lambda (spec context) #t)
                             'performance)))
                      (build-request-stage-plan request)
                      (loop (- remaining 1)))
                    #!void))))))
       (check make-calls => 0)
       (check (< elapsed 300.) => #t)))))
