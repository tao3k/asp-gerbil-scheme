(import :gerbil/runtime :gerbil/expander :gerbil/compiler)
(def (gxi-main . args) (error "unused interpreter branch"))
(def (gxc-main . args) (error "unused compiler branch"))
(def (find-runtime-symbol ctx id)
  (cond
   ((find-export-binding ctx id)
    => (lambda (bind)
         (unless (runtime-binding? bind)
           (error "export is not a runtime binding" id))
         (binding-id bind)))
   (else
    (error "module does not export symbol" (expander-context-id ctx) id))))

(def (find-export-binding ctx id)
  (cond
   ((find (match <>
            ((? module-export? xport)
            (and (eqv? (module-export-phi xport) 0)
                 (eq? (module-export-name xport) id)))
            (else #f))
          (module-context-export ctx))
    => core-resolve-module-export)
   (else #f)))

(def (tool-main program-name args)
  (cond
   ((equal? program-name "gxi")
    (apply gxi-main args))
   ((equal? program-name "gxc")
    (apply gxc-main args))
   (else
    (let* ((tool-id (string->symbol (string-append ":gerbil/tools/" program-name)))
           (tool-module (import-module tool-id #f #t))
           (tool-main-id (find-runtime-symbol tool-module 'main))
           (tool-main (eval tool-main-id)))
      (if (equal? program-name "gxtest")
        (exit (apply tool-main args))
        (apply tool-main args))))))

(def (main . args) (tool-main "gxtest" args))
