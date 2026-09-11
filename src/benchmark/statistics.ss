;;; -*- Gerbil -*-
;;; Exact nanosecond sample statistics shared by benchmark runners.
;;; Boundary: this module selects statistics; it never measures work.

(import :gerbil/gambit
        (only-in :std/sort sort)
        (only-in :std/sugar andmap))

(export benchmark-percentile-index
        benchmark-statistics-ref
        benchmark-sample-percentile
        benchmark-sample-statistics
        benchmark-select-sample)

;; : (-> Alist Symbol Value)
(def (benchmark-statistics-ref statistics key)
  (let (entry (assq key statistics))
    (and entry (cdr entry))))

;; : (-> Integer Integer Integer)
(def (benchmark-percentile-index sample-count percentile)
  (unless (> sample-count 0)
    (error "benchmark sample count must be positive" sample-count))
  (unless (and (integer? percentile)
               (> percentile 0)
               (<= percentile 100))
    (error "benchmark percentile must be an integer in [1, 100]"
           percentile))
  (- (quotient (+ (* percentile sample-count) 99) 100) 1))

;; : (-> (List Integer) (List Integer))
(def (benchmark-sorted-positive-nanoseconds samples)
  (unless (and (pair? samples)
               (andmap (lambda (sample)
                         (and (integer? sample) (> sample 0)))
                       samples))
    (error "benchmark samples must be positive integer nanoseconds" samples))
  (sort samples <))

;; : (-> (List Integer) Integer Integer)
(def (benchmark-sample-percentile samples percentile)
  (let (sorted (benchmark-sorted-positive-nanoseconds samples))
    (list-ref sorted
              (benchmark-percentile-index (length sorted) percentile))))

;; : (-> (List Integer) Alist)
(def (benchmark-sample-statistics samples)
  (let (sorted (benchmark-sorted-positive-nanoseconds samples))
    `((sampleCount . ,(length sorted))
      (samplesNs . ,samples)
      (minNs . ,(car sorted))
      (p50Ns . ,(list-ref sorted
                         (benchmark-percentile-index (length sorted) 50)))
      (p95Ns . ,(list-ref sorted
                         (benchmark-percentile-index (length sorted) 95)))
      (maxNs . ,(list-ref sorted (- (length sorted) 1))))))

;; : (-> (List Value) Integer (-> Value Integer) Value)
(def (benchmark-select-sample samples percentile projection)
  (unless (pair? samples)
    (error "benchmark sample set must be non-empty" samples))
  (let (sorted
        (sort samples
              (lambda (left right)
                (let ((left-ns (projection left))
                      (right-ns (projection right)))
                  (unless (and (integer? left-ns) (> left-ns 0)
                               (integer? right-ns) (> right-ns 0))
                    (error "benchmark projection must return positive integer nanoseconds"
                           left-ns
                           right-ns))
                  (< left-ns right-ns)))))
    (list-ref sorted
              (benchmark-percentile-index (length sorted) percentile))))
