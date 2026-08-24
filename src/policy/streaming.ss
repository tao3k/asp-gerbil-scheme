;;; -*- Gerbil -*-
;;; Bounded streaming prototype for file-local policy rules.

(import :gerbil/gambit
        :gslph/src/parser/package
        :gslph/src/parser/parse-workers
        :gslph/src/parser/source-scope
        :gslph/src/policy/agent-basic
        (only-in :std/sort sort)
        (only-in :std/srfi/1 drop take))

(export run-basic-agent-policy/streaming
        run-basic-agent-policy/streaming/selected)

;; The prototype deliberately keeps two accumulators.  Public policy ordering
;; is rule-major, so batch-local interleaving would be an observable regression.
;; Rich SourceFile values live only until both file-local rules consume a batch.
;; : (-> String Integer (List TypeFinding))
(def (run-basic-agent-policy/streaming root batch-size)
  (let* ((root (path-normalize root))
         (package (read-project-package root))
         (paths (sort (collect-source-files root package) string<?)))
    (run-basic-agent-policy/streaming/selected root paths batch-size)))

;; : (-> String (List String) Integer (List TypeFinding))
(def (run-basic-agent-policy/streaming/selected root paths batch-size)
  (when (< batch-size 1)
    (error "streaming policy batch size must be positive" batch-size))
  (let ((root (path-normalize root))
        (paths (sort paths string<?)))
    (let loop ((remaining paths)
               (generic-findings '())
               (vague-findings '()))
      (if (null? remaining)
        (append generic-findings vague-findings)
        (let* ((width (min batch-size (length remaining)))
               (batch-paths (take remaining width))
               (next-paths (drop remaining width))
               (source-files (parse-source-files root batch-paths))
               (next-generic
                (append generic-findings
                        (generic-owner-findings/files source-files)))
               (next-vague
                (append vague-findings
                        (vague-definition-findings/files source-files))))
          (set! source-files #f)
          (set! batch-paths #f)
          (##gc)
          (loop next-paths next-generic next-vague))))))
