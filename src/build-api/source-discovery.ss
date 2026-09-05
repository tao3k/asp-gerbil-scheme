;;; -*- Gerbil -*-
;;; One-shot source discovery for declarative package specs.

;; This public catalog function is the single upstream std/make discovery
;; boundary consumed by Builder Profile; keep it exported with the profile API.
(export all-gerbil-modules
        all-gerbil-modules/config
        all-gerbil-modules/roots/config
        git-project?
        +default-excluded-module-files+
        +default-project-exclude-directories+)

(import (rename-in :clan/building
                   (all-gerbil-modules upstream-all-gerbil-modules))
        (only-in :clan/filesystem path-is-script?)
        (only-in :std/misc/path path-expand path-normalize)
        (only-in :std/misc/ports read-all-as-lines)
        (only-in :std/misc/process filter-with-process run-process)
        (only-in :std/sort sort)
        (only-in :std/sugar hash-key? hash-put!)
        (only-in :std/srfi/1 append-map)
        (only-in :std/misc/list unique)
        (only-in :std/srfi/13 string-prefix?)
        (only-in :std/misc/string string-trim-eol))

(def +default-excluded-module-files+
  '("main.ss" "manifest.ss"))

(def +default-project-exclude-directories+
  '("run" ".git" "_darcs" ".gerbil"))

(def (path-under-excluded-directory? path directory)
  (string-prefix? (string-append directory "/") path))

(def (project-module-file? root path exclude exclude-dirs)
  (and (not (member path exclude))
       (not (ormap (cut path-under-excluded-directory? path <>) exclude-dirs))
       (not (path-is-script? (path-expand path root)))))

(def (git-project? root)
  (and
   ;; Most dependency packages are nested below another checkout. The local
   ;; marker rejects that case without spawning Git; worktree `.git` files and
   ;; ordinary `.git` directories are both accepted by `file-exists?`.
   (file-exists? (path-expand ".git" root))
   (with-catch
    (lambda (_) #f)
    (lambda ()
      (let* ((status 0)
             (answer
              (run-process
               ["git" "rev-parse" "--show-toplevel"]
               directory: root
               coprocess: read-line
               stderr-redirection: #t
               check-status:
               (lambda (value _settings)
                 (set! status value)))))
        (and (zero? status)
             (string? answer)
             ;; A nested package does not inherit an enclosing checkout's
             ;; ignore authority. Only the package root that owns the Git
             ;; worktree may project `.gitignore` into its source catalog.
             (string=? (path-normalize (path-expand "." root))
                       (path-normalize
                        (path-expand "." (string-trim-eol answer))))))))))

(def (upstream-project-modules root exclude exclude-dirs)
  (parameterize ((current-directory root))
    (sort
     (upstream-all-gerbil-modules
      exclude: exclude
      exclude-dirs: exclude-dirs)
     string<?)))

;; clan/building remains the source-catalog owner.  In a Git checkout, Git is
;; consulted once only as the ignore oracle for that already-discovered
;; catalog; untracked, unstaged Scheme files therefore remain build inputs.
(def (git-ignored-modules root modules)
  (with-catch
   (lambda (_) '())
   (lambda ()
     (filter-with-process
      ["git" "-c" "core.quotePath=false" "check-ignore" "--stdin"]
      (lambda (port)
        (for-each
         (lambda (module)
           (display module port)
           (newline port))
         modules))
      read-all-as-lines
      directory: root))))

(def (without-ignored-modules modules ignored)
  (let (ignored? (make-hash-table))
    (for-each (cut hash-put! ignored? <> #t) ignored)
    (filter (lambda (module) (not (hash-key? ignored? module))) modules)))

;; : (-> Boolean (List Path) (List Path))
(def (effective-project-exclude-directories default-project-excludes? exclude-dirs)
  (append (if default-project-excludes?
            +default-project-exclude-directories+
            [])
          exclude-dirs))

;; : (-> Path Path Path)
(def (source-root-module-path source-root module)
  (if (or (string=? source-root "")
          (string=? source-root "."))
    module
    (string-append source-root "/" module)))

;; : (-> Path Path (List Path) (List Path) (List Path))
(def (source-root-project-modules root source-root exclude exclude-dirs)
  (let (source-path (path-expand source-root root))
    (if (file-exists? source-path)
      (map (cut source-root-module-path source-root <>)
           (upstream-project-modules source-path exclude exclude-dirs))
      [])))

;; : (-> Path (List Path) Boolean (List Path))
(def (project-modules/ignore-filter root modules respect-gitignore?)
  (if (and respect-gitignore? (git-project? root))
    (without-ignored-modules
     modules
     (git-ignored-modules root modules))
    modules))

(def (all-gerbil-modules
      root: (root ".")
      exclude: (exclude +default-excluded-module-files+)
      exclude-dirs: (exclude-dirs '())
      default-project-excludes?: (default-project-excludes? #t)
      respect-gitignore?: (respect-gitignore? #t))
  (all-gerbil-modules/config
   root exclude exclude-dirs default-project-excludes? respect-gitignore?))

;;; AOT boundary:
;;; - Cross-module callers use this positional entry and never bind Gambit's
;;;   private keyword-dispatch implementation symbol.
;;; - The keyword API remains the declarative source surface in this owner.
;; : (-> Path (List Path) (List Path) Boolean Boolean (List Path))
(def (all-gerbil-modules/config
      root exclude exclude-dirs default-project-excludes? respect-gitignore?)
  (let (effective-exclude-dirs
        (effective-project-exclude-directories
         default-project-excludes? exclude-dirs))
    (let (modules
          (upstream-project-modules root exclude effective-exclude-dirs))
      (project-modules/ignore-filter root modules respect-gitignore?))))

;;; Root-scoped discovery keeps the Builder Profile roots authoritative from
;;; the first filesystem traversal. Git ignore evaluation remains owned by the
;;; package worktree root, after child-relative paths are restored.
;; : (-> Path (List Path) (List Path) (List Path) Boolean Boolean (List Path))
(def (all-gerbil-modules/roots/config
      root roots exclude exclude-dirs default-project-excludes? respect-gitignore?)
  (let* ((effective-exclude-dirs
          (effective-project-exclude-directories
           default-project-excludes? exclude-dirs))
         (modules
          (sort
           (unique
            (append-map
             (lambda (source-root)
               (source-root-project-modules
                root source-root exclude effective-exclude-dirs))
             roots))
           string<?)))
    (project-modules/ignore-filter root modules respect-gitignore?)))
