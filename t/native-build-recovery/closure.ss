;;; Compiler-owned import facts projected to a research JSON boundary.
(import :gerbil/expander :std/encoding/json
        (only-in :std/list/list append-map))
(export main)

(def (context-path ctx)
  (cond
   ((module-context? ctx)
    (let (path (module-context-path ctx))
      (unless (string? path) (error "Unsupported nested module path" path))
      path))
   ((prelude-context? ctx) #f)
   (else (error "Unsupported dependency context" ctx))))

(def (import-facts owner in (phi 0) (kind "context"))
  (cond
   ((module-context? in)
    [(hash ("from" owner) ("to" (symbol->string (expander-context-id in)))
           ("path" (context-path in)) ("phi" phi) ("kind" kind))])
   ((prelude-context? in)
    [(hash ("from" owner) ("to" (if (expander-context-id in)
                                     (symbol->string (expander-context-id in))
                                     "#implicit-prelude"))
           ("path" #f) ("phi" phi) ("kind" "prelude"))])
   ((module-import? in)
    (import-facts owner (module-import-source in) (+ phi (module-import-phi in)) "binding"))
   ((module-export? in)
    (import-facts owner (module-export-context in) (- phi (module-export-phi in)) kind))
   ((import-set? in)
    (append (import-facts owner (import-set-source in) (+ phi (import-set-phi in)) "set")
            (append-map (cut import-facts owner <>) (import-set-imports in))))
   (else (error "Unsupported import fact" in))))

(def (main . paths)
  (with-catch
    (lambda (e) (display-exception e (current-error-port)) (exit 70))
    (lambda ()
      (def rows
        (map (lambda (path)
               (def ctx (import-module path #f #f))
               (def id (symbol->string (expander-context-id ctx)))
               (hash ("id" id) ("path" (context-path ctx))
                     ("imports" (append-map (cut import-facts id <>) (module-context-import ctx)))))
             paths))
      (write-json (current-output-port) rows)
      (newline))))
