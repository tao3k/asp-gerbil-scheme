;;; -*- Gerbil -*-
;;; Test source-scope expansion and package-local import resolution.

(import :gerbil/gambit
        :asp-gerbil-scheme/src/parser/model
        :asp-gerbil-scheme/src/parser/package
        :asp-gerbil-scheme/src/parser/parse-workers
        :asp-gerbil-scheme/src/parser/source-file
        :asp-gerbil-scheme/src/parser/source-scope
        (only-in :std/sort sort)
        (only-in :std/srfi/13
                 string-index-right
                 string-prefix?))

(export +test-source-scope-import-depth+
        collect-source-scope
        collect-test-source-scope
        test-source-scope-files
        test-source-scope-import-entries
        package-local-import-source-paths
        package-local-import-source-path
        package-qualified-module-ref?
        test-runtime-shorthand-import?
        package-shorthand-module-ref?
        module-shorthand-ref?
        built-in-module-shorthand-ref?
        test-support-module-path
        test-runtime-relative-import?
        relative-module-ref?
        test-source-owner?
        relative-module-suffix
        source-owner-directory
        module-source-path
        package-source-roots
        module-source-path/candidates
        module-source-path/candidate
        collect-project-package-only)

;; : Integer
(def +test-source-scope-import-depth+ 2)

;; collect-source-scope
;;   : (-> String (List String) ProjectIndex)
;;   | doc m%
;;       `collect-source-scope root paths` reads package metadata and parses only
;;       the existing Gerbil/config files named by `paths`.
;;       # Examples
;;       ```scheme
;;       (project-index-files (collect-source-scope "." '("src/core.ss")))
;;       ;; => changed source-file facts
;;       ```
;;     %
(def (collect-source-scope root paths)
  (let* ((root (path-normalize root))
         (package (read-project-package root))
         (files (sort (changed-source-files root package paths) string<?)))
    (make-project-index root
                        (parse-source-files root files)
                        package)))

;; collect-test-source-scope
;;   : (-> String (List String) ProjectIndex)
;;   | doc m%
;;       `collect-test-source-scope root paths` keeps gxtest policy scoped to
;;       the supplied test/source entry files, then follows package-local
;;       imports so tested owners are checked without scanning the whole project.
;;     %
(def (collect-test-source-scope root paths)
  (let* ((root (path-normalize root))
         (package (read-project-package root))
         (source-files (test-source-scope-source-files root package paths)))
    (make-project-index root
                        source-files
                        package)))

;; test-source-scope-files
;;   : (-> Root MaybePackage (List Path) (List Path))
;;   | doc m%
;;       `test-source-scope-files root package paths` expands only the files
;;       selected by gxtest and package-local imports they actually reach.
;;
;;       # Examples
;;
;;       ```scheme
;;       (test-source-scope-files "." package '("t/unit-test.ss"))
;;       ;; => selected-source-files
;;       ```
;;     %
(def (test-source-scope-files root package paths)
  (map source-file-path
       (test-source-scope-source-files root package paths)))

;;; Boundary:
;;; - Import closure discovery needs parsed imports from every reached file.
;;; - The parsed source file is also the final ProjectIndex payload, so this
;;;   collector preserves files-scoped semantics without parsing every file a
;;;   second time during policy checks.
;; : (-> Root MaybePackage (List Path) (List SourceFile))
(def (test-source-scope-source-files root package paths)
  (sort (test-source-scope-source-files/walk
         root package '() '() '()
         (test-source-scope-initial-queue root package paths))
        source-file-path<?))

;; : (-> Root MaybePackage (List Path) (List ScopeEntry))
(def (test-source-scope-initial-queue root package paths)
  (map (lambda (path) [path 0])
       (changed-source-files root package paths)))

;;; Scope traversal keeps the shallowest route to each path. A module first
;;; reached at the depth limit must be re-expanded if a later test reaches it
;;; from a shallower owner; otherwise policy findings depend on test order.
;; : (-> (List (Pair Path Integer)) Path Integer Boolean)
(def (test-source-scope-seen-at-or-shallower-depth? seen-paths path depth)
  (let (entry (assoc path seen-paths))
    (and entry
         (<= (cdr entry) depth))))

;; : (-> Root MaybePackage (List Path) (List Path) (List SourceFile) (List ScopeEntry) (List SourceFile))
(def (test-source-scope-source-files/walk root package seen-paths seen-relpaths
                                         source-files queue)
  (match queue
    ([]
     source-files)
    ([[path depth] . rest]
     (test-source-scope-source-files/entry
      root package seen-paths seen-relpaths source-files path depth rest))))

;; : (-> Root MaybePackage (List Path) (List Path) (List SourceFile) Path Integer (List ScopeEntry) (List SourceFile))
(def (test-source-scope-source-files/entry root package seen-paths seen-relpaths
                                          source-files path depth rest)
  (if (test-source-scope-seen-at-or-shallower-depth?
       seen-paths path depth)
    (test-source-scope-source-files/walk
     root package seen-paths seen-relpaths source-files rest)
    (let* ((file (parse-source-file root path))
           (relpath (source-file-path file))
           (seen-paths (cons (cons path depth) seen-paths))
           (already-collected? (member relpath seen-relpaths))
           (imports
            (test-source-scope-import-entries
             root package relpath depth
             (source-file-imports file))))
      (test-source-scope-source-files/walk
       root package
       seen-paths
       (if already-collected?
         seen-relpaths
         (cons relpath seen-relpaths))
       (if already-collected?
         source-files
         (cons file source-files))
       (foldr cons rest imports)))))

;; : (-> SourceFile SourceFile Boolean)
(def (source-file-path<? left right)
  (string<? (source-file-path left)
            (source-file-path right)))

;; : (-> Root MaybePackage Path Integer (List ModuleRef) (List ScopeEntry))
(def (test-source-scope-import-entries root package owner-path depth imports)
  (if (>= depth +test-source-scope-import-depth+)
    []
    (map (lambda (path) [path (fx1+ depth)])
          (changed-source-files
           root package
           (package-local-import-source-paths
           root package owner-path depth imports)))))

;; : (-> Root MaybePackage Path Integer (List ModuleRef) (List Path))
(def (package-local-import-source-paths root package owner-path depth imports)
  (let (paths '())
    (for-each
     (lambda (module)
       (let (path (package-local-import-source-path root package owner-path depth module))
         (when path
           (set! paths (cons path paths)))))
     imports)
    (reverse paths)))

;; : (-> Root MaybePackage Path Integer ModuleRef (Maybe Path))
(def (package-local-import-source-path root package owner-path depth module)
  (and (string? module)
       (cond
        ((package-qualified-module-ref? package module)
         (module-source-path
          root package
          (substring module
                     (string-length
                      (string-append ":" (project-package-name package) "/"))
                     (string-length module))))
        ((test-runtime-shorthand-import? root owner-path depth module)
         (module-source-path root package
                             (substring module 1 (string-length module))))
        ((test-runtime-relative-import? owner-path depth module)
         (module-source-path root package
                             (relative-module-suffix owner-path module)))
        (else #f))))

;; : (-> MaybePackage ModuleRef Boolean)
(def (package-qualified-module-ref? package module)
  (and package
       (project-package-name package)
       (string-prefix?
        (string-append ":" (project-package-name package) "/")
        module)))

;; : (-> Root Path Integer ModuleRef Boolean)
(def (test-runtime-shorthand-import? root owner-path depth module)
  (and (= depth 0)
       (test-source-owner? owner-path)
       (package-shorthand-module-ref? module)
       (not (test-support-module-path root module))))

;; : (-> ModuleRef Boolean)
(def (package-shorthand-module-ref? module)
  (and (module-shorthand-ref? module)
       (not (built-in-module-shorthand-ref? module))))

;; : (-> ModuleRef Boolean)
(def (module-shorthand-ref? module)
  (string-prefix? ":" module))

;; : (-> ModuleRef Boolean)
(def (built-in-module-shorthand-ref? module)
  (or (string-prefix? ":gerbil/" module)
      (string-prefix? ":std/" module)))

;; : (-> Root ModuleRef (Maybe Path))
(def (test-support-module-path root module)
  (and (package-shorthand-module-ref? module)
       (module-source-path/candidates
        root
        [(string-append "t/" (substring module 1 (string-length module)))])))

;; : (-> Path Integer ModuleRef Boolean)
(def (test-runtime-relative-import? owner-path depth module)
  (and (= depth 0)
       (test-source-owner? owner-path)
       (relative-module-ref? module)
       (not (test-source-owner? (relative-module-suffix owner-path module)))))

;; : (-> ModuleRef Boolean)
(def (relative-module-ref? module)
  (or (string-prefix? "./" module)
      (string-prefix? "../" module)))

;; : (-> Path Boolean)
(def (test-source-owner? path)
  (string-prefix? "t/" path))

;; : (-> Path ModuleRef ModuleSuffix)
(def (relative-module-suffix owner-path module)
  (path-normalize
   (string-append (source-owner-directory owner-path) "/" module)))

;; : (-> Path Path)
(def (source-owner-directory path)
  (let (ix (string-index-right path #\/))
    (if ix
      (substring path 0 ix)
      ".")))

;; : (-> Root MaybePackage ModuleSuffix (Maybe Path))
(def (module-source-path root package suffix)
  (or (module-source-path/candidates root [suffix])
      (module-source-path/candidates
       root
       (map (lambda (source-root)
              (string-append source-root "/" suffix))
            (package-source-roots package)))))

;; : (-> MaybePackage (List Path))
(def (package-source-roots package)
  (let (policy (and package (project-package-source-scope-policy package)))
    (if policy
      (source-scope-policy-roots policy)
      ["src"])))

;; module-source-path/candidates
;;   : (-> Root (List ModuleSuffix) (Maybe Path))
;;   | doc m%
;;       `module-source-path/candidates root candidates` returns the first
;;       package-local module path whose Gerbil source file exists.
;;
;;       # Examples
;;
;;       ```scheme
;;       (module-source-path/candidates "." '("src/core"))
;;       ;; => "src/core.ss"
;;       ```
;;     %
(def (module-source-path/candidates root candidates)
  (let find-candidate ((rest candidates))
    (match rest
      ([]
       #f)
      ([candidate . more]
       (or (module-source-path/candidate root candidate)
           (find-candidate more))))))

;; : (-> Root ModuleSuffix (Maybe Path))
(def (module-source-path/candidate root suffix)
  (find (lambda (candidate)
          (file-exists? (path-expand candidate root)))
        (map (lambda (extension)
               (string-append suffix extension))
             +source-extensions+)))

;; collect-project-package-only
;;   : (-> String ProjectIndex )
;;   | doc m%
;;       `collect-project-package-only root` returns package metadata without
;;       parsing source owners, which keeps package-policy checks lightweight.
;;
;;       # Examples
;;       ```scheme
;;       (project-index-files (collect-project-package-only "."))
;;       ;; => ()
;;       ```
;;     %
;; : (-> String ProjectIndex)
(def (collect-project-package-only root)
  (let* ((root (path-normalize root))
         (package (read-project-package root)))
    (make-project-index root '() package)))
