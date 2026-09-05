;;; -*- Gerbil -*-
;;; Bounded streaming prototype for file-local policy rules.

(import :gerbil/gambit
        :asp-gerbil-scheme/src/parser/package
        :asp-gerbil-scheme/src/parser/parse-workers
        :asp-gerbil-scheme/src/parser/source-scope
        :asp-gerbil-scheme/src/policy/agent-basic
        (only-in :std/sort sort)
        (only-in :std/srfi/1 drop fold take))

(export run-basic-agent-policy/streaming
        run-basic-agent-policy/streaming/selected)

;; The prototype deliberately keeps two accumulators.  Public policy ordering
;; is rule-major, so batch-local interleaving would be an observable regression.
;; Rich SourceFile values live only until both file-local rules consume a batch.
;; run-basic-agent-policy/streaming
;;   : (-> Path PositiveInteger (List TypeFinding))
;;   | doc m%
;;       Parse the package source catalog in bounded batches and return the
;;       basic agent-policy findings in stable rule-major order.
;;       # Examples
;;       ```scheme
;;       (run-basic-agent-policy/streaming "." 32)
;;       ;; => findings
;;       ```
;;       Result: one ordered finding list without retaining every SourceFile.
;;     %
(def (run-basic-agent-policy/streaming root batch-size)
  (let* ((root (path-normalize root))
         (package (read-project-package root))
         (paths (sort (collect-source-files root package) string<?)))
    (run-basic-agent-policy/streaming/selected root paths batch-size)))

;; run-basic-agent-policy/streaming/selected
;;   : (-> Path (List Path) PositiveInteger (List TypeFinding))
;;   | doc m%
;;       Apply the bounded streaming policy to an explicit owner set.
;;       # Examples
;;       ```scheme
;;       (run-basic-agent-policy/streaming/selected "." ["src/core.ss"] 1)
;;       ;; => findings
;;       ```
;;       Result: findings preserve owner order inside each rule family.
;;     %
(def (run-basic-agent-policy/streaming/selected root paths batch-size)
  (when (< batch-size 1)
    (error "streaming policy batch size must be positive" batch-size))
  (let ((root (path-normalize root))
        (paths (sort paths string<?)))
    (let loop ((remaining paths)
               (generic-findings '())
               (vague-findings '()))
      (if (null? remaining)
        (fold cons (reverse vague-findings) generic-findings)
        (let* ((width (min batch-size (length remaining)))
               (batch-paths (take remaining width))
               (next-paths (drop remaining width))
               (source-files (parse-source-files root batch-paths))
               (next-generic
                (fold cons
                      generic-findings
                      (generic-owner-findings/files source-files)))
               (next-vague
                (fold cons
                      vague-findings
                      (vague-definition-findings/files source-files))))
          (set! source-files #f)
          (set! batch-paths #f)
          (##gc)
          (loop next-paths next-generic next-vague))))))
