;;; -*- Gerbil -*-
;;; One-shot source discovery for declarative package specs.

(export all-gerbil-modules
        git-project?
        +default-project-exclude-directories+)

(import (rename-in :clan/building
                   (all-gerbil-modules upstream-all-gerbil-modules))
        (only-in :clan/filesystem path-is-script?)
        (only-in :std/misc/path path-expand)
        (only-in :std/misc/ports read-all-as-lines)
        (only-in :std/misc/process filter-with-process run-process)
        (only-in :std/sort sort)
        (only-in :std/sugar hash-key? hash-put!)
        (only-in :std/srfi/13 string-prefix?)
        (only-in :std/misc/string string-trim-eol))

(def +default-excluded-module-files+
  '("main.ss" "manifest.ss"))

(def +default-project-exclude-directories+
  '("run" "t" ".git" "_darcs" ".gerbil"))

(def (path-under-excluded-directory? path directory)
  (string-prefix? (string-append directory "/") path))

(def (project-module-file? root path exclude exclude-dirs)
  (and (not (member path exclude))
       (not (ormap (cut path-under-excluded-directory? path <>) exclude-dirs))
       (not (path-is-script? (path-expand path root)))))

(def (git-project? root)
  (with-catch
   (lambda (_) #f)
   (lambda ()
     (let* ((status 0)
            (answer
             (run-process
              ["git" "rev-parse" "--is-inside-work-tree"]
              directory: root
              coprocess: read-line
              stderr-redirection: #t
              check-status:
              (lambda (value _settings)
                (set! status value)))))
       (and (zero? status)
            (string? answer)
            (string=? (string-trim-eol answer) "true"))))))

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

(def (all-gerbil-modules
      root: (root ".")
      exclude: (exclude +default-excluded-module-files+)
      exclude-dirs: (exclude-dirs '()))
  (let (effective-exclude-dirs
        (append +default-project-exclude-directories+ exclude-dirs))
    (let (modules
          (upstream-project-modules root exclude effective-exclude-dirs))
      (if (git-project? root)
        (without-ignored-modules
         modules
         (git-ignored-modules root modules))
        modules))))
