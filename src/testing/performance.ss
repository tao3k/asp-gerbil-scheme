;;; -*- Gerbil -*-
;;; POO receipt extension around the native benchmark API.
;;;
;;; The upstream test command remains responsible for suite execution. This
;;; module only instruments an explicit thunk selected by a test case.

(import :gerbil/gambit
        (only-in :asp-gerbil-scheme/src/benchmark/gate
                 benchmark-run/result)
        (only-in :clan/poo/object .o)
        (only-in :std/srfi/1 filter))

(export testing-benchmark-run/result
        testing-benchmark-body-phase)

;; : (forall (a) (-> [(Pair Symbol a)] Symbol (Maybe a)))
;; : (-> Alist Symbol Value)
(def (testing-benchmark-ref receipt key (default #f))
  (match (assq key receipt)
    ([ _ . value] value)
    (else default)))

;; : (forall (a) (-> [(Pair Symbol a)] Symbol [(Pair Symbol a)]))
;; : (-> Alist Symbol Alist)
(def (testing-benchmark-details-without details key)
  (filter (lambda (entry) (not (eq? (car entry) key))) details))

;; : (forall (a) (-> Symbol [(Pair Symbol a)] [(Pair Symbol a)] POOObject))
;; : (-> Symbol Alist Alist POOObject)
(def (testing-benchmark-body-phase benchmark-name receipt (details []))
  (let* ((elapsed-nanos (testing-benchmark-ref receipt 'elapsedNs 0))
         (elapsed-ms (/ elapsed-nanos 1000000))
         (phase (testing-benchmark-ref details 'phase 'benchmark-body))
         (phase-details (testing-benchmark-details-without details 'phase)))
    (.o kind: 'testing-profile-receipt
        profile: 'performance
        status: (if (eq? (testing-benchmark-ref receipt 'status 'fail) 'pass)
                  'ok
                  'failed)
        name: benchmark-name
        details:
        (append `((phase . ,phase)
                  (name . ,benchmark-name)
                  (elapsedNs . ,elapsed-nanos)
                  (elapsedMs . ,elapsed-ms)
                  (memoryBefore
                   . ,(testing-benchmark-ref receipt 'memoryBefore []))
                  (memoryAfter
                   . ,(testing-benchmark-ref receipt 'memoryAfter []))
                  (memoryDelta
                   . ,(testing-benchmark-ref receipt 'memoryDelta [])))
                phase-details))))

;; : (forall (a) (-> Symbol Alist (-> a) Alist (Values Alist a POOObject)))
;; : (-> Symbol Alist Procedure Alist (Values Alist Value POOObject))
(def (testing-benchmark-run/result name fixture thunk (details []))
  (call-with-values
   (lambda () (benchmark-run/result fixture thunk))
   (lambda (receipt result)
     (values receipt
             result
             (testing-benchmark-body-phase name receipt details)))))
