;;; -*- Gerbil -*-
;;; Fast-path entrypoint for search guide output.

(import :gerbil/gambit
        :asp-gerbil-scheme/src/commands/guide-sections)

(export main)

;;; Arg normalization:
;;; - Fast-path binaries may be invoked as `search guide` or directly as `guide`.
;;; - Strip the routing prefix and leave topic/rule flags untouched.
;; : (-> CommandLine Args )
(def (search-guide-args)
  (let (args (cddr (command-line)))
    (cond
     ((and (pair? args)
           (equal? (car args) "search")
           (pair? (cdr args))
           (equal? (cadr args) "guide"))
      (cddr args))
     ((and (pair? args)
          (equal? (car args) "guide"))
      (cdr args))
     (else args))))

;;; Entrypoint:
;;; - Guide sections own rendering content.
;;; - This wrapper only adapts process argv to line output.
;; : (-> Args ExitCode )
(def (main . args)
  (for-each displayln (guide-section-lines-for args))
  0)

(exit (apply main (search-guide-args)))
