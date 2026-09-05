;;; -*- Gerbil -*-
;;; Build-time ASP source coverage declarations.

(import :gerbil/gambit
        (only-in "./builder-profile"
                 asp-gerbil-scheme-development-builder-profile
                 asp-gerbil-scheme-builder-profile-exclude-directories
                 asp-gerbil-scheme-builder-profile-modules/root-roots)
        (only-in :std/misc/path path-expand path-normalize)
        (only-in :std/sort sort))

(export asp-gerbil-scheme-source-coverage
        asp-gerbil-scheme-load-source-coverage
        asp-gerbil-scheme-source-coverage-roots
        asp-gerbil-scheme-source-coverage-exclude-directories
        asp-gerbil-scheme-source-coverage-declared-files
        asp-gerbil-scheme-source-coverage-owner-root
        asp-gerbil-scheme-source-coverage-files)

;; : (List Path)
(def current-source-coverage-roots '("src"))
;; : (List Path)
(def current-source-coverage-exclude-directories '())
;; : (Maybe (List Path))
(def current-source-coverage-declared-files #f)
;; : (Maybe Root)
(def current-source-coverage-owner-root #f)
;; `build.ss` files call this declaration so ASP can parse the project source
;; coverage universe. Build support also consumes the same declaration so policy
;; gates and std/make coverage stay tied to the package's build entrypoint.
;; : (forall (A) (-> roots: (List Path) exclude-directories: (List Path) files: (Maybe (List Path)) owner-root: (Maybe Root) explanation: (Maybe A) Unit))
(def (asp-gerbil-scheme-source-coverage roots: (roots '())
                            exclude-directories: (exclude-directories '())
                            files: (files #f)
                            owner-root: (owner-root #f)
                            explanation: (explanation #f))
  (set! current-source-coverage-roots roots)
  (set! current-source-coverage-exclude-directories exclude-directories)
  (set! current-source-coverage-declared-files
        (and files (sort files string<?)))
  (set! current-source-coverage-owner-root
        (path-normalize (or owner-root (current-directory))))
  #!void)

;; : (-> Root Unit)
(def (asp-gerbil-scheme-load-source-coverage root)
  (let (owner-root (path-normalize (path-expand root)))
    (unless (and current-source-coverage-declared-files
                 (equal? owner-root current-source-coverage-owner-root))
      (let* ((profile asp-gerbil-scheme-development-builder-profile)
             (roots current-source-coverage-roots)
             (files
              (asp-gerbil-scheme-builder-profile-modules/root-roots
               profile owner-root roots)))
        (asp-gerbil-scheme-source-coverage
         roots: roots
         exclude-directories:
         (asp-gerbil-scheme-builder-profile-exclude-directories profile)
         files: files
         owner-root: owner-root)))))

;; : (-> (List Path))
(def (asp-gerbil-scheme-source-coverage-roots)
  current-source-coverage-roots)

;; : (-> (List Path))
(def (asp-gerbil-scheme-source-coverage-exclude-directories)
  current-source-coverage-exclude-directories)

;; : (-> (Maybe (List Path)))
(def (asp-gerbil-scheme-source-coverage-declared-files)
  current-source-coverage-declared-files)

;; : (-> (Maybe Root))
(def (asp-gerbil-scheme-source-coverage-owner-root)
  current-source-coverage-owner-root)

;; : (-> Root (List Path))
(def (asp-gerbil-scheme-source-coverage-files root)
  (asp-gerbil-scheme-load-source-coverage root)
  (or (asp-gerbil-scheme-source-coverage-declared-files)
      (error "source coverage requires the Build API module catalog")))
