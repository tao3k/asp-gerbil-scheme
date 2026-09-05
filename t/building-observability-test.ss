(import :std/text/json
        ../src/building/model
        ../src/building/observability)

(def (assert-true label value)
  (unless value
    (error "building observability assertion failed" label value)))


(def (exercise-control-plane)
  (let loop ((remaining 2000000) (sum 0))
    (if (zero? remaining)
        sum
        (loop (- remaining 1) (+ sum remaining)))))

(let* ((observation
        (build-action-observe! 3 exercise-control-plane))
       (summary
        (build-plan-observations-summary->json-object (list observation))))
  (assert-true 'receipt
               (integer? (build-stage-observation-receipt observation)))
  (assert-true 'work-item-count
               (= 3 (build-stage-observation-work-item-count observation)))
  (assert-true 'wall-seconds
               (>= (build-stage-observation-wall-seconds observation) 0.0))
  (assert-true 'control-plane-cpu-seconds
               (>= (build-stage-observation-control-plane-cpu-seconds observation)
                   0.0))
  (assert-true 'control-plane-cpu-utilization
               (>= (build-stage-observation-control-plane-cpu-utilization observation)
                   0.0))
  (assert-true 'control-plane-gc-count
               (>= (build-stage-observation-control-plane-gc-count observation) 0.0))
  (assert-true 'control-plane-allocated-bytes
               (>= (build-stage-observation-control-plane-allocated-bytes observation)
                   0.0))
  (assert-true 'summary-stage-count
               (= 1 (hash-get summary "stage-count")))
  (assert-true 'summary-work-item-count
               (= 3 (hash-get summary "work-item-count")))
  (assert-true 'summary-native-child-scope
               (eq? #f (hash-get summary "native-child-cpu-included")))
  (write-build-plan-observations-summary-json (list observation)))

(let* ((guard (make-build-elapsed-budget-guard 5.0))
       (observations
        (build-observe-sequence/guard!
         '(first second)
         (lambda (item)
           (build-action-observe! 1 (lambda () item)))
         guard
         (lambda (_observation _completed-count _elapsed-seconds) #!void))))
  (assert-true 'guarded-sequence-completes
               (= 2 (length observations)))
  (assert-true 'elapsed-budget-allows-under-limit
               (guard 'after-item 4.9 1 (car observations)))
  (assert-true 'elapsed-budget-blocks-over-limit
               (not (guard 'after-item 5.1 1 (car observations)))))

(let ((blocked?
       (with-catch
        (lambda (_exception) #t)
        (lambda ()
          (build-observe-sequence/guard!
           '(first second)
           (lambda (item)
             (build-action-observe! 1 (lambda () item)))
           (lambda (_phase _elapsed-seconds completed-count _subject)
             (< completed-count 1))
           (lambda (_observation _completed-count _elapsed-seconds) #!void))
          #f))))
  (assert-true 'guard-blocks-sequence-at-boundary blocked?))

(let* ((receipt
        (make-build-stage-receipt
         "json-stage" 'std/make 'compiled "JSON projection" 'made 7))
       (observation
        (build-action-observe! 2 (lambda () receipt)))
       (json
        (build-plan-observations->json-string (list observation)))
       (object (string->json-object json))
       (stages (hash-get object "stages"))
       (stage (car stages)))
  (assert-true 'json-schema
               (equal? "asp-gerbil-scheme.build-observations.v1"
                       (hash-get object "schema")))
  (assert-true 'json-stage-label
               (equal? "json-stage" (hash-get stage "label")))
  (assert-true 'json-stage-kind
               (equal? "std/make" (hash-get stage "kind")))
  (assert-true 'json-native-child-scope
               (eq? #f (hash-get object "native-child-cpu-included"))))
