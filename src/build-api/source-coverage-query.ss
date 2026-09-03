;;; -*- Gerbil -*-
;;; Process-local lifecycle state for declaration-only build.ss loads.

(import :gerbil/gambit
        (only-in :std/misc/path path-expand path-normalize))

(export asp-gerbil-scheme-register-source-coverage-query!
        asp-gerbil-scheme-consume-source-coverage-query!)

;; (List Path)
(def source-coverage-query-files '())

;; : (-> Path Void)
(def (asp-gerbil-scheme-register-source-coverage-query! source-file)
  (let (path (path-normalize (path-expand source-file)))
    (unless (member path source-coverage-query-files)
      (set! source-coverage-query-files
            (cons path source-coverage-query-files)))))

;; : (-> Path Boolean)
;;; The loaded build script calls its generated main after `load` returns.
;;; Consume the matching path exactly once so a later explicit invocation in
;;; the same process remains a real build instead of inheriting query state.
(def (asp-gerbil-scheme-consume-source-coverage-query! source-file)
  (let (path (path-normalize (path-expand source-file)))
    (if (member path source-coverage-query-files)
      (begin
        (set! source-coverage-query-files
              (filter (lambda (candidate) (not (equal? candidate path)))
                      source-coverage-query-files))
        #t)
      #f)))
