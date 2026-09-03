;;; -*- Gerbil -*-
;;; Build-time ASP source coverage declarations.

(import :gerbil/gambit
        (only-in "./source-coverage-query"
                 asp-gerbil-scheme-register-source-coverage-query!)
        (only-in :std/misc/path path-expand path-normalize)
        (only-in :std/sort sort))

(export asp-gerbil-scheme-source-coverage
        asp-gerbil-scheme-load-source-coverage
        asp-gerbil-scheme-source-coverage-roots
        asp-gerbil-scheme-source-coverage-runtime-roots
        asp-gerbil-scheme-source-coverage-exclude-directories
        asp-gerbil-scheme-source-coverage-declared-files
        asp-gerbil-scheme-source-coverage-files)

;; : (List Path)
(def current-source-coverage-roots '("src"))
;; : (Maybe (List Path))
(def current-source-coverage-runtime-roots #f)
;; : (List Path)
(def current-source-coverage-exclude-directories '())
;; : (Maybe (List Path))
(def current-source-coverage-declared-files #f)
;; : (Maybe Root)
(def current-source-coverage-owner-root #f)
;; `build.ss` files call this declaration so ASP can parse the project source
;; coverage universe. Build support also consumes the same declaration so policy
;; gates and std/make coverage stay tied to the package's build entrypoint.
;; : (forall (A) (-> roots: (List Path) runtime-roots: (Maybe (List Path)) exclude-directories: (List Path) files: (Maybe (List Path)) explanation: (Maybe A) Unit))
(def (asp-gerbil-scheme-source-coverage roots: (roots '())
                            runtime-roots: (runtime-roots #f)
                            exclude-directories: (exclude-directories '())
                            files: (files #f)
                            explanation: (explanation #f))
  (set! current-source-coverage-roots roots)
  (set! current-source-coverage-runtime-roots runtime-roots)
  (set! current-source-coverage-exclude-directories exclude-directories)
  (set! current-source-coverage-declared-files
        (and files (sort files string<?)))
  (set! current-source-coverage-owner-root
        (path-normalize (current-directory)))
  #!void)

;; : (-> Root Unit)
(def (asp-gerbil-scheme-load-source-coverage root)
  (let* ((owner-root (path-normalize (path-expand root)))
         (build-file (path-expand "build.ss" owner-root)))
    (unless (and current-source-coverage-declared-files
                 (equal? owner-root current-source-coverage-owner-root))
      (unless (file-exists? build-file)
        (error "Build API source coverage requires build.ss" owner-root))
      (set! current-source-coverage-declared-files #f)
      (set! current-source-coverage-owner-root #f)
      ;; Gerbil may invoke a loaded script's main after `load` returns.  Keep a
      ;; process-local path receipt instead of relying on dynamic extent.
      (asp-gerbil-scheme-register-source-coverage-query! build-file)
      (with-directory owner-root
        (lambda ()
          (load build-file)))
      (unless (and current-source-coverage-declared-files
                   (equal? owner-root current-source-coverage-owner-root))
        (error "build.ss did not declare a Build API module catalog"
               owner-root)))))

;; : (-> (List Path))
(def (asp-gerbil-scheme-source-coverage-roots)
  current-source-coverage-roots)

;; : (-> (List Path))
(def (asp-gerbil-scheme-source-coverage-runtime-roots)
  (or current-source-coverage-runtime-roots
      current-source-coverage-roots))

;; : (-> (List Path))
(def (asp-gerbil-scheme-source-coverage-exclude-directories)
  current-source-coverage-exclude-directories)

;; : (-> (Maybe (List Path)))
(def (asp-gerbil-scheme-source-coverage-declared-files)
  current-source-coverage-declared-files)

;; : (-> Root (List Path))
(def (asp-gerbil-scheme-source-coverage-files root)
  (asp-gerbil-scheme-load-source-coverage root)
  (or (asp-gerbil-scheme-source-coverage-declared-files)
      (error "source coverage requires the Build API module catalog")))

;; : (forall (A) (-> Path (-> A) A))
(def (with-directory directory thunk)
  (let (previous (current-directory))
    (dynamic-wind
      (lambda () (current-directory directory))
      thunk
      (lambda () (current-directory previous)))))
