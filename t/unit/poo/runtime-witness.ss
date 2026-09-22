;;; -*- Gerbil -*-
;;; Boundary:
;;; - test owner records policy expectations.
;;; - Keep typed contracts and fixture intent explicit.
(import :std/test
        :std/string/misc)
(export check-poo-runtime-witnesses)
;; ParsedData
(def (load-poo-runtime!)
  (eval '(import :clan/poo/proto
                 :clan/poo/object
                 :clan/poo/brace
                 :clan/poo/debug
                 :clan/poo/io
                 :clan/poo/type
                 :gerbil/runtime/gambit
                 :std/misc/repr
                 :std/encoding/json)))
;; TypeSpec
(def (check-poo-prototype-runtime-witness)
  (load-poo-runtime!)
  (check (eval '((instantiate-proto
                  (compose-proto
                   (lambda (next base)
                     (lambda (x) (+ 1 (base x))))
                   (lambda (next base)
                     (lambda (x) (* 2 (base x)))))
                  (lambda (x) x))
                 3))
         => 7)
  (check (eval '((instantiate-proto
                  (compose-proto*
                   [(lambda (next base)
                      (lambda (x) (+ 1 (base x))))
                    (lambda (next base)
                      (lambda (x) (* 2 (base x))))])
                  (lambda (x) x))
                 3))
         => 7))
;; Json
(def (check-poo-json-print-runtime-witness)
  (load-poo-runtime!)
  (check (eval '(begin
                  (def json-object {a: 1 b: 2})
                  (with-output-to-string
                    (lambda () (write-json json-object)))))
         => "{\"a\":1,\"b\":2}")
  (check (eval '(begin
                  (def printable-object {sexp: `(ok 1)})
                  (with-output-to-string
                    (lambda () (pr printable-object)))))
         => "(ok 1)"))
;; CheckPooWriteenvMethodDispatchWitness
(def (check-poo-writeenv-method-dispatch-witness)
  (load-poo-runtime!)
  (check (eval '(procedure? (method-ref {a: 1} `:wr))) => #t)
  (check (eval '(procedure? (method-ref (TJ String "\"abc\"") `:wr))) => #t)
  (check (eval '(procedure? (method-ref (TJ Json "{\"a\":1}") `:wr))) => #t))
;; CheckPooTraceRuntimeWitness
(def (check-poo-trace-runtime-witness)
  (load-poo-runtime!)
  (def trace-result #f)
  (def trace-output
    (with-output-to-string
      (lambda ()
        (parameterize ((current-error-port (current-output-port)))
          (set! trace-result
            (eval '(begin
                     (.def trace-base
                       (foo (lambda (x) (+ x 1))))
                     (def traced (trace-poo trace-base `trace-base))
                     ((.@ traced foo) 4))))))))
  (check trace-result => 5)
  (check (and (string-contains trace-output "(.@ trace-base foo)") #t) => #t))
;; CheckPooRuntimeWitnesses
(def (check-poo-runtime-witnesses)
  (check-poo-prototype-runtime-witness)
  (check-poo-json-print-runtime-witness)
  (check-poo-writeenv-method-dispatch-witness)
  (check-poo-trace-runtime-witness))
