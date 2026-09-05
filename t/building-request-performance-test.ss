(export building-request-performance-test)

(import :std/test
        :asp-gerbil-scheme/src/building/facade)

(def (elapsed-ms thunk)
  (let (start (time->seconds (current-time)))
    (thunk)
    (* 1000. (- (time->seconds (current-time)) start))))

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
              []
              (native-toolchain-default)))
            (stage-specs
             [["alpha.ss"] ["beta.ss"] ["gamma.ss"] ["delta.ss"]])
            (elapsed
             (elapsed-ms
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
