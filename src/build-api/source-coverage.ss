;;; -*- Gerbil -*-
;;; Build-time ASP source coverage declarations.

(import :gerbil/gambit
        (only-in :std/misc/path directory-files path-expand)
        (only-in :std/sort sort)
        (only-in :std/srfi/13 string-suffix?)
        (only-in :std/sugar with-catch))

(export gslph-source-coverage
        gslph-load-source-coverage
        gslph-source-coverage-roots
        gslph-source-coverage-runtime-roots
        gslph-source-coverage-exclude-directories
        gslph-source-coverage-files-for-roots
        gslph-source-coverage-files)

;; : (List Path)
(def current-source-coverage-roots '("src"))
;; : (Maybe (List Path))
(def current-source-coverage-runtime-roots #f)
;; : (List Path)
(def current-source-coverage-exclude-directories '())

;; `build.ss` files call this declaration so ASP can parse the project source
;; coverage universe. Build support also consumes the same declaration so policy
;; gates and std/make coverage stay tied to the package's build entrypoint.
;; : (forall (A) (-> roots: (List Path) runtime-roots: (Maybe (List Path)) exclude-directories: (List Path) explanation: (Maybe A) Unit))
(def (gslph-source-coverage roots: (roots '())
                            runtime-roots: (runtime-roots #f)
                            exclude-directories: (exclude-directories '())
                            explanation: (explanation #f))
  (set! current-source-coverage-roots roots)
  (set! current-source-coverage-runtime-roots runtime-roots)
  (set! current-source-coverage-exclude-directories exclude-directories)
  #!void)

;; : (-> Root Unit)
(def (gslph-load-source-coverage root)
  (let (build-file (path-expand "build.ss" root))
    (when (file-exists? build-file)
      (with-directory root
        (lambda ()
          (load build-file))))))

;; : (-> (List Path))
(def (gslph-source-coverage-roots)
  current-source-coverage-roots)

;; : (-> (List Path))
(def (gslph-source-coverage-runtime-roots)
  (or current-source-coverage-runtime-roots
      current-source-coverage-roots))

;; : (-> (List Path))
(def (gslph-source-coverage-exclude-directories)
  current-source-coverage-exclude-directories)

;; : (-> Root (List Path))
(def (gslph-source-coverage-files root)
  (gslph-source-coverage-files-for-roots
   root
   (gslph-source-coverage-roots)))

;; Explicit include roots are the source of truth for downstream build graphs.
;; This keeps library materialization on the same declared source universe
;; without widening it to unrelated command or compatibility directories.
;; : (-> Root (List Path) (List Path))
(def (gslph-source-coverage-files-for-roots root roots)
  (sort (apply append
               (map (lambda (coverage-root)
                      (source-coverage-root-files root coverage-root))
                    roots))
        string<?))

;; : (-> Root Path (List Path))
(def (source-coverage-root-files root coverage-root)
  (let (directory (path-expand coverage-root root))
    (if (source-coverage-directory? directory)
      (map (lambda (path)
             (string-append coverage-root "/" path))
           (source-coverage-directory-files directory ""))
      [])))

;; : (-> Path Boolean)
(def (source-coverage-directory? path)
  (with-catch
   (lambda (_) #f)
   (lambda ()
     (eq? (file-info-type (file-info path)) 'directory))))

;; : (-> String Boolean)
(def (source-coverage-gerbil-source? path)
  (string-suffix? ".ss" path))

;; : (-> Path Boolean)
(def (source-coverage-skipped-entry? entry)
  (or (member entry '("." ".."))
      (member entry (gslph-source-coverage-exclude-directories))))

;; : (-> Path Path)
(def (source-coverage-child-path directory entry)
  (path-expand entry directory))

;; : (-> Path Path)
(def (source-coverage-relative-path prefix entry)
  (if (string=? prefix "")
    entry
    (string-append prefix "/" entry)))

;; : (-> Path Path (List Path))
(def (source-coverage-entry-files directory prefix entry)
  (let* ((path (source-coverage-child-path directory entry))
         (relative-path (source-coverage-relative-path prefix entry)))
    (cond
     ((source-coverage-skipped-entry? entry) [])
     ((source-coverage-directory? path)
      (source-coverage-directory-files path relative-path))
     ((source-coverage-gerbil-source? entry)
      [relative-path])
     (else []))))

;; : (-> Path Path (List Path))
(def (source-coverage-directory-files directory prefix)
  (apply append
         (map (lambda (entry)
                (source-coverage-entry-files directory prefix entry))
              (sort (directory-files directory) string<?))))

;; : (forall (A) (-> Path (-> A) A))
(def (with-directory directory thunk)
  (let (previous (current-directory))
    (dynamic-wind
      (lambda () (current-directory directory))
      thunk
      (lambda () (current-directory previous)))))
