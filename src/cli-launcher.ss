;;; -*- Gerbil -*-
;;; Native launcher for per-command Gerbil Scheme harness executables.

(import :gerbil/gambit
  :asp-gerbil-scheme/src/protocol/command-catalog
        (only-in :asp-gerbil-scheme/src/constants +help+)
        (only-in :asp-gerbil-scheme/src/protocol/command-catalog
                 provider-dynamic-command-dispatch
                 provider-recognized-command-names)
        (only-in :asp-gerbil-scheme/src/search-light-launcher try-search-light-main)
        (only-in :std/misc/path path-expand)
        (only-in :std/misc/ports read-all-as-string)
        (only-in :std/srfi/13 string-contains string-index string-index-right string-prefix?)
        (only-in :std/sugar foldl))
(export main
        command-line-args
        provider-command-line-args
        register-static-command-dispatch!)

;;; Install boundary:
;;; - The native launcher is the command boundary. It dispatches subcommands
;;;   in-process so an installed harness is one native executable.

;; : (List String)
(def +launcher-names+
  '("gxi" "asp-gerbil-scheme"))

;; Keep the executable boundary safe even when a stale parser artifact is
;; accidentally selected during static linking.
(def +native-owner-max-source-bytes+ (* 1024 1024))

(def static-command-dispatch [])

;; : (-> (List StaticCommandDispatch) Void)
(def (register-static-command-dispatch! entries)
  (set! static-command-dispatch entries))

;;; Launcher argv boundary:
;;; - Keep this tiny normalization local so the release launcher does not
;;;   statically link the full command graph.
;; : (-> (List String) (List String))
(def (command-line-args argv)
  (or (command-line-command-tail argv)
      (strip-launcher-frames argv)))

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
  (or (launcher-name? arg)
      (launcher-binary-path? arg)
      (launcher-script-path? arg)))

;; : (-> String Boolean)
(def (launcher-name? arg)
  (member arg +launcher-names+))

;; : (-> String Boolean)
(def (launcher-binary-path? arg)
  (or (string-suffix? "/gxi" arg)
      (string-suffix? "/asp-gerbil-scheme" arg)))

;; : (-> String Boolean)
(def (launcher-script-path? arg)
  (or (equal? arg "src/cli.ss")
      (equal? arg "src/cli-launcher.ss")
      (string-suffix? "/src/cli.ss" arg)
      (string-suffix? "/src/cli-launcher.ss" arg)))

;;; Public CLI:
;;; - Help stays in-process so `asp gerbil-scheme --help` has no startup dependency on the
;;;   command graph.
;;; - Subcommands are handled by native launcher fast paths or direct in-process
;;;   dispatch. Missing native coverage is a hard implementation error.
;; : (-> (List String) Boolean)
(def (help-args? args)
  (or (null? args)
      (and (null? (cdr args))
           (member (car args) '("-h" "--help" "help")))))

;; : (-> Integer Integer)
(def (emit-help status)
  (display +help+)
  status)

;; : (-> String (List String) Integer)
(def (dispatch-command command rest)
  (or (try-native-search-command command rest)
      (try-native-direct-source-query command rest)
      (dispatch-native-command command rest)))

;; : (-> String (List String) (U Integer #f))
(def (try-native-search-command command rest)
  (and (equal? command "search")
       (begin
         (guard-native-owner-search! rest)
         (try-search-light-main rest))))

;; : (-> Args Unit )
(def (guard-native-owner-search! args)
  (when (and (pair? args)
             (equal? (car args) "owner")
             (pair? (cdr args)))
    (let* ((owner (cadr args))
           (root (or (launcher-option "--workspace" args) "."))
           (path (path-expand owner (path-expand root))))
      (when (file-exists? path)
        (guard-native-source-path! path)))))

;; : (-> Path Unit )
(def (guard-native-source-path! path)
  (let (bytes (file-info-size (file-info path)))
    (when (> bytes +native-owner-max-source-bytes+)
      (error "source exceeds native Scheme read budget; use asp search/query"
             path bytes))))

;;; Direct query boundary:
;;; - Hook selector reads must be a native launcher fast path.
;;; - Do not import `:asp-gerbil-scheme/src/cli`; that pulls in parser/checker
;;;   modules before reading a small line range.
;; : (-> String (List String) (U Integer #f))
(def (try-native-direct-source-query command rest)
  (and (equal? command "query")
       (let ((from-hook (launcher-option "--from-hook" rest))
             (selector (launcher-option "--selector" rest)))
         (cond
          ((and from-hook
                (equal? from-hook "direct-source-read")
                (not selector))
           (error "direct-source-read requires --selector"))
          ((and selector (launcher-direct-source-selector? selector))
           (emit-native-direct-source-query rest selector)
           0)
          (else #f)))))

;; : (-> String (List String) (U String #f))
(def (launcher-option name args)
  (cond
   ((null? args) #f)
   ((equal? (car args) name)
    (and (pair? (cdr args)) (cadr args)))
   (else
    (launcher-option name (cdr args)))))

;; : (-> String Boolean)
(def (launcher-direct-source-selector? selector)
  (and (not (launcher-structural-selector? selector))
       (or (string-contains selector "/")
           (string-contains selector ".")
           (string-contains selector ":"))))

;; : (-> String Boolean)
(def (launcher-structural-selector? selector)
  (string-prefix? "gerbil-scheme://" selector))

;; : (-> String (List String) Boolean)
(def (launcher-flag? name args)
  (and (member name args) #t))

;;; Search owner-items fast path:
;;; - Provider search evidence must come from the local checkout during binary
;;;   validation; dynamic command loading can resolve stale global modules.
;; : (-> String (List String) (U Integer #f))
;; : (-> (List String) Selector Integer)
(def (emit-native-direct-source-query rest selector)
  (let* ((workspace (or (launcher-option "--workspace" rest) "."))
         (code (launcher-read-selector workspace selector)))
    (if (launcher-flag? "--json" rest)
      (begin
        (display "{\"selector\":")
        (write selector)
        (display ",\"code\":")
        (write code)
        (displayln "}"))
      (display code))))

;; : (-> String String String)
(def (launcher-read-selector root selector)
  (let* ((parts (launcher-split-selector selector))
         (path (car parts))
         (start (cadr parts))
         (end (caddr parts))
         (source-path (path-expand path root)))
    (guard-native-source-path! source-path)
    (if (and start end)
      (launcher-read-line-range source-path start end)
      (call-with-input-file source-path read-all-as-string))))

;; : (-> String SelectorParts)
(def (launcher-split-selector selector)
  (let (ix (string-index-right selector #\:))
    (if ix
      (let* ((path (substring selector 0 ix))
             (range (substring selector (fx1+ ix) (string-length selector)))
             (dash (string-index range #\-)))
        (if dash
          [path
           (string->number (substring range 0 dash))
           (string->number (substring range (fx1+ dash) (string-length range)))]
          (let* ((prev (string-index-right path #\:))
                 (start-text (and prev (substring path (fx1+ prev) (string-length path))))
                 (start (and start-text (string->number start-text)))
                 (end (string->number range)))
            (if (and prev start end)
              [(substring path 0 prev) start end]
              [path end end]))))
      [selector #f #f])))

;; launcher-read-line-range
;;   : (-> String Integer Integer String)
;;   | doc m%
;;       Read the inclusive one-based line range from `path`.
;;
;;       This is intentionally local to the launcher fast path so hook source
;;       reads do not import the full parser/check command graph.
;;
;;       # Examples
;;
;;       ```scheme
;;       (launcher-read-line-range "src/cli.ss" 1 2)
;;       ;; => first two source lines
;;       ```
;;     %
(def (launcher-read-line-range path start end)
  (call-with-input-file path
    (lambda (port)
      (call-with-output-string
       (lambda (out)
         (let loop ((line-number 1))
           (when (<= line-number end)
             (let (line (read-line port))
               (unless (eof-object? line)
                 (when (>= line-number start)
                   (display line out)
                   (newline out))
                 (loop (fx1+ line-number)))))))))))

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
