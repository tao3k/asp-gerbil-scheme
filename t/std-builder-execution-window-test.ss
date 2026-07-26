(import (only-in :clan/poo/object object<-alist)
        :std/test
        ../src/building/model
        ../src/building/native-toolchain
        (only-in ../src/building/persistent-worker
                 make-gxi-persistent-worker-pool
                 make-persistent-worker-result
                 persistent-worker-pool-close!
                 persistent-worker-pool-run-window!
                 persistent-worker-pool-worker-count
                 persistent-worker-request-spec)
        ../src/building/std-builder)

(export std-builder-execution-window-test main)

(def (make-fake-execution-window-controller
      window-size
      observed-rss-values
      next-window-sizes
      (hard-max-rss-bytes 4096)
      (worker-count 2)
      (headroom-bytes 512))
  (let (observed-rss-bytes
        (if (pair? observed-rss-values)
          (car observed-rss-values)
          0))
    (object<-alist
     `((kind . gslph.execution-window-controller.v1)
       (worker-count . ,worker-count)
       (hard-max-rss-bytes . ,hard-max-rss-bytes)
       (headroom-bytes . ,headroom-bytes)
       (window-size . ,window-size)
       (.observe-run! .
        ,(lambda (label thunk)
           (make-execution-window-observation
            (thunk)
            'completed
            512
            observed-rss-bytes
            hard-max-rss-bytes
            1)))
       (.next-state .
        ,(lambda (observation spec-count)
           (make-fake-execution-window-controller
            (if (pair? next-window-sizes)
              (car next-window-sizes)
              window-size)
            (if (pair? observed-rss-values)
              (cdr observed-rss-values)
              [])
            (if (pair? next-window-sizes)
              (cdr next-window-sizes)
              [])
            hard-max-rss-bytes
            worker-count
            headroom-bytes)))))))

(def std-builder-execution-window-test
  (test-suite "std-builder execution windows"
    (test-case "topology groups flatten into one ordered execution window"
      (check
       (topology-groups->upstream-execution-windows
        '((prepare compile) () (link package)))
       => '((prepare compile link package))))

    (test-case "empty topology groups produce no execution window"
      (check (topology-groups->upstream-execution-windows '()) => '())
      (check (topology-groups->upstream-execution-windows '(() ())) => '()))

    (test-case "adaptive controller preserves order across sequential windows"
      (let (calls 0)
        (let* ((make-proc
                (lambda args
                  (set! calls (+ calls 1))
                  args))
               (builder
                (make-std-builder
                 "fake-std/make"
                 make-proc
                 'compile
                 "fake upstream make"
                 #f
                 []
                 (native-toolchain-default)))
               (controller
                (make-fake-execution-window-controller
                 2
                 '(1024 1536)
                 '(3)))
               (plan
                (make-adaptive-execution-window-plan
                 '((prepare compile) (link package publish))
                 controller))
               (result (std-builder-run-spec! builder plan []))
               (windows
                (adaptive-execution-window-result-execution-windows result))
               (observations
                (adaptive-execution-window-result-window-observations result)))
          (check (adaptive-execution-window-result? result) => #t)
          (check windows => '((prepare compile) (link package publish)))
          (check (length observations) => 2)
          (check
           (map execution-window-observation-outcome observations)
           => '(completed completed))
          (check (apply append windows)
                 => '(prepare compile link package publish))
          (check calls => 2))))

    (test-case "adaptive empty plan invokes no upstream make session"
      (let (calls 0)
        (let* ((builder
                (make-std-builder
                 "fake-std/make"
                 (lambda args
                   (set! calls (+ calls 1))
                   args)
                 'compile
                 "fake upstream make"
                 #f
                 []
                 (native-toolchain-default)))
               (controller
                (make-fake-execution-window-controller 2 '() '()))
               (result
                (std-builder-run-spec!
                 builder
                 (make-adaptive-execution-window-plan '() controller)
                 [])))
          (check
           (adaptive-execution-window-result-execution-windows result)
           => '())
          (check calls => 0))))

    (test-case "one adaptive spec over the hard cap fails closed"
      (let* ((builder
              (make-std-builder
               "fake-std/make"
               (lambda args args)
               'compile
               "fake upstream make"
               #f
               []
               (native-toolchain-default)))
             (controller
              (make-fake-execution-window-controller
               1 '(8192) '() 4096))
             (blocked?
              (with-catch
               (lambda (_exception) #t)
               (lambda ()
                 (std-builder-run-spec!
                  builder
                  (make-adaptive-execution-window-plan
                   '((only-spec)) controller)
                  [])
                 #f))))
        (check blocked? => #t)))

    (test-case "one topology window invokes the upstream make procedure once"
      (let (calls 0)
        (let* ((make-proc
                (lambda args
                  (set! calls (+ calls 1))
                  (void)))
               (builder
                (make-std-builder
                 "fake-std/make"
                 make-proc
                 'compile
                 "fake upstream make"
                 #f
                 []
                 (native-toolchain-default)))
               (windows
                (topology-groups->upstream-execution-windows
                 '((prepare compile) (link package)))))
          (for-each
           (lambda (window)
             (std-builder-run-spec! builder window []))
           windows)
          (check calls => 1))))

    (test-case
        "persistent workers serve one dependency-free topology group"
      (let ((dispatched-windows [])
            (closed? #f)
            (upstream-calls 0))
        (let* ((builder
                (make-std-builder
                 "fake-std/make"
                 (lambda args
                   (set! upstream-calls (+ upstream-calls 1))
                   args)
                 'compile
                 "fake upstream make"
                 #f
                 []
                 (native-toolchain-default)))
               (controller
                (make-fake-execution-window-controller
                 2 '(1024 1024 1024 1024) '(2 1 2) 4096 2))
               (pool
                (object<-alist
                 `((kind . gslph.persistent-worker-pool.v1)
                   (worker-count . 2)
                   (.run-window! .
                    ,(lambda (requests)
                       (let (specs
                             (map persistent-worker-request-spec requests))
                         (set! dispatched-windows
                           (append dispatched-windows (list specs))))
                       (map
                        (lambda (request)
                          (make-persistent-worker-result
                           request "fake-worker" 'completed 1 "ok"))
                        requests)))
                   (.close! .
                    ,(lambda ()
                       (set! closed? #t)
                       (void))))))
               (plan
                (make-adaptive-execution-window-plan
                 '((prepare compile link package publish))
                 controller
                 (lambda (received-builder received-controller)
                   (check received-builder => builder)
                   (check received-controller => controller)
                   pool)))
               (result (std-builder-run-spec! builder plan [])))
          (check dispatched-windows
                 => '((prepare compile) (link) (package publish)))
          (check
           (adaptive-execution-window-result-execution-windows result)
           => dispatched-windows)
          (check
           (length
            (adaptive-execution-window-result-window-observations result))
           => 3)
          (check upstream-calls => 0)
          (check closed? => #t))))

    (test-case
        "multiple topology groups delegate dependency scheduling upstream"
      (let ((upstream-windows [])
            (pool-created? #f))
        (let* ((builder
                (make-std-builder
                 "fake-std/make"
                 (lambda args
                   (set! upstream-windows
                     (append upstream-windows (list args)))
                   (void))
                 'compile
                 "fake upstream make"
                 #f
                 []
                 (native-toolchain-default)))
               (controller
                (make-fake-execution-window-controller
                 2 '(1024 1024 1024 1024) '(2 1 2) 4096 2))
               (plan
                (make-adaptive-execution-window-plan
                 '((prepare compile link) (package publish))
                 controller
                 (lambda _args
                   (set! pool-created? #t)
                   (error "multi-group plan must stay upstream-owned"))))
               (result (std-builder-run-spec! builder plan []))
               (expected-windows
                '((prepare compile) (link package) (publish)))
               (expected-upstream-calls
                (map list expected-windows)))
          (check upstream-windows => expected-upstream-calls)
          (check
           (adaptive-execution-window-result-execution-windows result)
           => expected-windows)
          (check
           (length
            (adaptive-execution-window-result-window-observations result))
           => 3)
          (check pool-created? => #f))))

    (test-case "concrete gxi pool completes its JSON lifecycle"
      (let (pool (make-gxi-persistent-worker-pool 2))
        (check (persistent-worker-pool-worker-count pool) => 2)
        (check (persistent-worker-pool-run-window! pool []) => '())
        (persistent-worker-pool-close! pool)))

    (test-case "current topology window stays skipped without invoking make"
      (let (calls 0)
        (let* ((make-proc
                (lambda args
                  (set! calls (+ calls 1))
                  (void)))
               (builder
                (make-std-builder
                 "fake-std/make"
                 make-proc
                 'compile
                 "fake upstream make"
                 #f
                 []
                 (native-toolchain-default)))
               (windows
                (topology-groups->upstream-execution-windows
                 '((prepare compile) (link package))))
               (stages
                (std-builder-stage-plan
                 builder
                 windows
                 (lambda (stage context) #t)
                 (lambda (spec) "topology-window")
                 []
                 (lambda (stage context result) (void))))
               (receipt (build-stage-run! (car stages) [])))
          (check (build-stage-receipt-status receipt) => 'skipped)
          (check calls => 0))))))

(def (main . args)
  (run-tests! std-builder-execution-window-test))
