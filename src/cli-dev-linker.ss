;;; -*- Gerbil -*-
;;; Development executable root for asp-gerbil-scheme.

(import :gerbil/gambit
        (only-in :std/misc/path path-expand)
        (only-in :asp-gerbil-scheme/src/support/args executable-argv))
(export main
        dev-linker-run)

;;; Dev binary boundary:
;;; - Keep the executable root thin.  Search owner-items has a launcher-native
;;;   fast path; broader command implementations remain dynamic.

;; : (-> Args Integer)
(def (dev-linker-run args)
  (add-load-path! (path-expand ".gerbil/lib" (current-directory)))
  (##global-var-set! (##make-global-var 'load-module) load-module)
  (load-module "asp-gerbil-scheme/src/cli-launcher")
  (let (launcher-main (eval 'asp-gerbil-scheme/src/cli-launcher#main))
    (unless (procedure? launcher-main)
      (error "provider-runtime-source-mismatch"
             "asp-gerbil-scheme/src/cli-launcher"
             'asp-gerbil-scheme/src/cli-launcher#main
             launcher-main))
    (apply launcher-main args)))

;; : (-> Args Integer)
(def (main . args)
  (exit (dev-linker-run (executable-argv args))))

;; : (-> Args Args)
(def (executable-argv fallback)
  (let (argv (command-line))
    (if (pair? argv)
      (cdr argv)
      fallback)))
