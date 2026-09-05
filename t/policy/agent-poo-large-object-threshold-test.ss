;;; -*- Gerbil -*-
;;; Gerbil scheme harness POO large-object threshold policy.

(import :gerbil/gambit
        :std/test
        :asp-gerbil-scheme/src/benchmark/gate
        (only-in :asp-gerbil-scheme/src/parser/model make-call-fact)
        :asp-gerbil-scheme/src/policy/agent-poo-callees
        :asp-gerbil-scheme/src/policy/agent-poo-object-literal)

(export agent-poo-large-object-threshold-policy-test)

;; : Alist
(def large-object-threshold-benchmark
  (make-benchmark-fixture
   'GERBIL-SCHEME-AGENT-POLICY-033
   'poo-large-object-threshold-short-circuit
   "POO large object threshold short-circuit"
   "20k-slot-equivalent .o call arguments"
   "stop after the configured threshold instead of counting every slot"
   '(poo large-object threshold short-circuit)))

;; : Integer
(def +large-object-threshold-slot-count+ 20000)

;; : (-> Integer Value Value)
(def (large-poo-keyword-prefix slots tail)
  (let loop ((remaining slots) (args tail))
    (if (zero? remaining)
      args
      (loop (- remaining 1)
            (cons "value" (cons "slot:" args))))))

;; : (-> [String] CallFact)
(def (large-poo-call args)
  (make-call-fact ".o"
                  (* 2 +large-object-threshold-slot-count+)
                  "src/large/object.ss"
                  1
                  1
                  args
                  '()
                  "build-large-object"))

;; PolicyTest
(def agent-poo-large-object-threshold-policy-test
  (test-suite "gerbil scheme harness POO large-object threshold policy"
    (test-case "large .o threshold checks short-circuit before full slot counting"
      (let* ((args
              (large-poo-keyword-prefix
               +poo-data-object-literal-min-slot-specs+
               "unreachable-tail"))
             (call (large-poo-call args))
             (receipt
              (benchmark-run
               large-object-threshold-benchmark
               (lambda ()
                 (poo-object-literal-slot-spec-count>=?
                  call
                  +poo-data-object-literal-min-slot-specs+)))))
        (check (benchmark-receipt-pass? receipt) => #t)
        (check (benchmark-fixture-ref receipt 'feature)
               => 'poo-large-object-threshold-short-circuit)
        (check (poo-object-literal-slot-spec-count>=?
                call
                +poo-data-object-literal-min-slot-specs+)
               => #t)))))
