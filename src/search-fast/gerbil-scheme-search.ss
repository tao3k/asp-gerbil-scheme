;;; -*- Gerbil -*-
;;; Compatibility wrapper for the full search command entrypoint.

(import :gerbil/gambit
        :asp-gerbil-scheme/src/commands/search)

(def args (cddr (command-line)))
(def search-args
  (if (and (pair? args)
           (equal? (car args) "search"))
    (cdr args)
    args))

(exit (search-main search-args))
