;;; -*- Gerbil -*-
;;; Native launcher for per-command Gerbil Scheme harness executables.

(import :gerbil/gambit
  :asp-gerbil-scheme/src/protocol/command-catalog
        (only-in :asp-gerbil-scheme/src/runtime/provider-http-json-command-client
                 provider-http-json-query-main)
        (only-in :asp-gerbil-scheme/src/constants +help+)
        (only-in :asp-gerbil-scheme/src/protocol/command-catalog
                 provider-dynamic-command-dispatch
                 provider-recognized-command-names)
        (only-in :std/misc/path path-expand)
        (only-in :std/srfi/13 string-suffix?)
        (only-in :std/sugar ormap))
(export main
        command-line-args
        provider-command-line-args
        register-static-command-dispatch!)

;; : (List String)
(def +launcher-names+
  '("gxi" "asp-gerbil-scheme"))

;; : (Vector StaticCommandDispatch)
(def static-command-dispatch [])

;; : (-> (List StaticCommandDispatch) Void)
(def (register-static-command-dispatch! entries)
  (set! static-command-dispatch entries))

;;; Launcher argv boundary:
;;; - Keep this tiny normalization local so the release launcher does not
;;;   statically link the full command graph.
;; : (-> (List String) (List String))
(def (command-line-args argv)
  (match (command-line-command-tail argv)
    (#f (strip-launcher-frames argv))
    (tail tail)))

;; : (-> (List String) (List String))
(def provider-command-line-args command-line-args)

;;; Argv search boundary:
;;; - Walk over wrapper frames until the first known command appears.
;;; - Returning the remaining tail preserves subcommand flags verbatim.
;; : (-> (List String) (Maybe (List String)))
(def (command-line-command-tail argv)
  (match argv
    ([] #f)
    ([arg . rest]
     (if (member arg provider-recognized-command-names)
       argv
       (command-line-command-tail rest)))))

;;; Launcher-frame boundary:
;;; - Strip only known interpreter and launcher frames from the front.
;;; - Stop at the first non-frame argument so user paths are not rewritten.
;; : (-> (List String) (List String))
(def (strip-launcher-frames argv)
  (match argv
    ([] [])
    ([arg . rest]
     (if (launcher-frame? arg)
       (strip-launcher-frames rest)
       argv))))

;; : (-> String Boolean)
(def (launcher-frame? arg)
  (ormap (lambda (predicate) (predicate arg))
         [launcher-name? launcher-binary-path? launcher-script-path?]))

;; : (-> String Boolean)
(def (launcher-name? arg)
  (ormap (lambda (name) (equal? arg name)) +launcher-names+))

;; : (-> String Boolean)
(def (launcher-binary-path? arg)
  (ormap (lambda (suffix) (string-suffix? suffix arg))
         ["/gxi" "/asp-gerbil-scheme"]))

;; : (-> String Boolean)
(def (launcher-script-path? arg)
  (ormap (lambda (path)
           (or (equal? arg path)
               (string-suffix? (string-append "/" path) arg)))
         ["src/cli.ss" "src/cli-launcher.ss"]))

;;; Public CLI:
;;; - Help stays in-process so `asp gerbil-scheme --help` has no startup dependency on the
;;;   command graph.
;;; - Subcommands are handled by native launcher fast paths or direct in-process
;;;   dispatch. Missing native coverage is a hard implementation error.
;; : (-> (List String) Boolean)
(def (help-args? args)
  (match args
    ([] #t)
    ([arg] (member arg '("-h" "--help" "help")))
    (else #f)))

;; : (-> Integer Integer)
(def (emit-help status)
  (display +help+)
  status)

;; : (-> String (List String) Integer)
(def (dispatch-command command rest)
  (match command
    ("query"
     (provider-http-json-query-main rest))
    (else (dispatch-native-command command rest))))

;; : (-> String (List String) Integer)
(def (dispatch-native-command command rest)
  (dispatch-dynamic-command command rest))

;;; Dynamic dispatch boundary:
;;; - Hot commands stay in the launcher.
;;; - Cold/full commands load only after argv selects them, so `bench` and
;;;   native search cannot accidentally pay parser/checker startup cost.
;; : (-> String (List String) Integer)
(def (dispatch-dynamic-command command rest)
  (let (static-entry (find-dynamic-command command static-command-dispatch))
    (if static-entry
      ((cadr static-entry) rest)
      (let (entry (find-dynamic-command command provider-dynamic-command-dispatch))
        (if entry
          (let (command-main
                (begin
                  (ensure-runtime-loader!)
                  (dynamic-command-main (cadr entry) (caddr entry))))
            (command-main rest))
          (emit-help 2))))))

;; : (-> String (List CommandDispatch) MaybeCommandDispatch)
(def (find-dynamic-command command entries)
  (match entries
    ([] #f)
    ([entry . more]
     (if (equal? command (car entry))
       entry
       (find-dynamic-command command more)))))

;; : (-> Unit)
(def (ensure-runtime-loader!)
  (##global-var-set! (##make-global-var 'load-module) load-module)
  (launcher-add-runtime-load-paths!))

;; : (-> Unit)
(def (launcher-add-runtime-load-paths!)
  ;; Installed artifacts are hermetic: cli-install-linker already mounted the
  ;; sibling artifact lib directory. Global/development paths are allowed
  ;; only for the developer launcher.
  (unless (equal? (getenv "ASP_GERBIL_SCHEME_ARTIFACT_ONLY" #f) "1")
    (launcher-add-load-path! (path-expand ".gerbil/lib" (current-directory)))
    (launcher-add-load-path! (path-expand "lib" (gerbil-home)))
    (launcher-add-load-path! (path-expand "lib" (gerbil-path)))))

;; : (-> Path Unit)
(def (launcher-add-load-path! path)
  (when (file-exists? path)
    (add-load-path! path)))

;; : (-> String Symbol Procedure)
(def (dynamic-command-main module-id binding-id)
  (load-module module-id)
  (let (binding (eval binding-id))
    (if (procedure? binding)
      binding
      (error "provider-runtime-source-mismatch" module-id binding-id binding))))

;; : (-> (List String) Integer)
(def (main . args)
  (cond
   ((help-args? args)
    (emit-help 0))
   ((and (pair? args)
         (member (car args) provider-recognized-command-names))
    (dispatch-command (car args) (cdr args)))
   (else
    (emit-help 2))))
