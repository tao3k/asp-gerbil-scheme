;;; -*- Gerbil -*-
;;; Parser-owned source scope and filesystem discovery helpers.
;;; Boundary:
;;; - Package policy owns source/test roots and exclusions.
;;; - This module turns that policy into concrete parser file sets.

(import :gerbil/gambit
        :gslph/src/parser/package
        (only-in :gslph/src/parser/selectors relative-path source-full-path)
        (only-in :std/iter for/fold)
        (only-in :std/misc/list unique)
        (only-in :std/misc/ports read-file-lines)
        (only-in :std/sort sort)
        (only-in :std/srfi/13
                 string-contains
                 string-index-right
                 string-prefix?
                 string-suffix?)
        (only-in :std/sugar cut filter ormap))

(export +source-extensions+
        +config-files+
        +ignored-dirs+
        minimal-scan-roots
        collect-source-files
        collect-source-files-preview
        changed-source-files
        gerbil-source-path?
        source-line-count
        read-source-lines)

;; ConfigConstant
(def +source-extensions+ '(".ss" ".ssi" ".scm" ".sld"))
;; ConfigConstant
(def +config-files+ '("gerbil.pkg" "build.ss"))
;; Boolean
(def +ignored-dirs+
  '(".devenv" ".git" ".cache" ".run" ".gerbil" "build" "dist" "target"
    "src/gambit" "tree-sitter"
    "t/scenarios" "t/fixtures" "t/snapshots"))

;; : (-> (List Path) (List Path))
(def (minimal-scan-roots roots)
  (filter
   (lambda (candidate)
     (not
      (ormap (lambda (other)
               (and (not (equal? candidate other))
                    (path-under-scan-root? candidate other)))
             roots)))
   roots))

;; collect-source-files
;;   : (-> String MaybePackage (List String))
;;   | doc m%
;;       `collect-source-files root package` returns config files plus configured
;;       runtime/test source files after applying package-owned source scope.
;;
;;       # Examples
;;
;;       ```scheme
;;       (member "gerbil.pkg" (collect-source-files "." #f))
;;       ;; => #t
;;       ```
;;     %
(def (collect-source-files root . maybe-package)
  (let* ((package (and (pair? maybe-package) (car maybe-package)))
         (scope-policy (and package
                            (project-package-source-scope-policy package)))
         (source-roots (configured-source-roots scope-policy))
         (test-roots (configured-test-roots package))
         (scan-roots
          (minimal-scan-roots (unique (append source-roots test-roots))))
         (ignored-dirs (append +ignored-dirs+
                               (if scope-policy
                                 (source-scope-policy-exclude-directories scope-policy)
                                 '()))))
    (unique
     (map path-normalize
          (append (root-config-files root)
                  (apply append
                         (map (lambda (source-root)
                                (let (path (path-expand source-root root))
                                  (if (source-directory? path)
                                    (walk-source-directory root path ignored-dirs)
                                    '())))
                              scan-roots)))))))

;; collect-source-files-preview
;;   : (-> String Integer MaybePackage (List String))
;;   | doc m%
;;       `collect-source-files-preview root limit package` returns a bounded,
;;       deterministic source preview without walking the full workspace.
;;
(def (collect-source-files-preview root limit . maybe-package)
  (let* ((package (and (pair? maybe-package) (car maybe-package)))
         (scope-policy (and package
                            (project-package-source-scope-policy package)))
         (source-roots (configured-source-roots scope-policy))
         (test-roots (configured-test-roots package))
         (scan-roots
          (minimal-scan-roots (unique (append source-roots test-roots))))
         (ignored-dirs (append +ignored-dirs+
                               (if scope-policy
                                 (source-scope-policy-exclude-directories scope-policy)
                                 '())))
         (configs (take-up-to (root-config-files root) limit))
         (remaining (- limit (length configs))))
    (unique
     (map path-normalize
          (append configs
                  (if (> remaining 0)
                    (scan-source-files-preview root scan-roots ignored-dirs remaining)
                    '()))))))

;;; Preview walker boundary:
;;; - Keep the traversal deterministic and stop as soon as the limit is filled.
;;; - The local add-file/walk helpers preserve one shared remaining counter.
;; : (-> Path Boolean )
(def (source-preview-entry? entry)
  (not (member entry '("." ".."))))
;; : (-> Root Path Path (List String) Procedure Procedure Unit )
(def (scan-source-preview-entry root dir entry ignored-dirs walk add-file)
  (when (source-preview-entry? entry)
    (let (path (path-expand entry dir))
      (cond
       ((and (source-directory? path)
             (not (ignored-source-directory? root path entry ignored-dirs)))
        (walk path))
       ((gerbil-source-path? path)
        (add-file path))
       (else #!void)))))
;; : (-> Root (List Path) (List String) Integer (List Path))
(def (scan-source-files-preview root scan-roots ignored-dirs limit)
  (let ((result '())
        (remaining limit))
    (def (add-file path)
      (when (> remaining 0)
        (set! result (cons path result))
        (set! remaining (- remaining 1))))
    (def (walk dir)
      (when (> remaining 0)
        (for-each
         (lambda (entry)
           (when (> remaining 0)
             (scan-source-preview-entry
              root dir entry ignored-dirs walk add-file)))
         (sort (directory-files dir) string<?))))
    (for-each
     (lambda (source-root)
       (when (> remaining 0)
         (let (path (path-expand source-root root))
           (when (source-directory? path)
             (walk path)))))
     scan-roots)
    (reverse result)))

;; : (forall (a) (-> (List a) Integer (List a)))
(def (take-up-to values limit)
  (cond
   ((or (<= limit 0) (null? values)) '())
   (else (cons (car values)
               (take-up-to (cdr values) (- limit 1))))))

;;; Changed-file indexing:
;;; - Git reports paths relative to the workspace root.
;;; - Changed mode validates reported paths directly against the same
;;;   source-scope/exclude rules as full collection, without first walking the
;;;   entire project.
;;; - Deleted, non-source, generated, or otherwise out-of-scope files do not
;;;   force a parse or produce policy noise.
;;; - Parser ownership stays here instead of duplicated by the check command.
;; : (-> Root MaybePackage (List Path) (List Path) )
(def (changed-source-files root package paths)
  (let* ((scope-policy (and package
                            (project-package-source-scope-policy package)))
         (source-roots (configured-source-roots scope-policy))
         (test-roots (configured-test-roots package))
         (scan-roots (unique (append source-roots test-roots)))
         (ignored-dirs (append +ignored-dirs+
                               (if scope-policy
                                 (source-scope-policy-exclude-directories scope-policy)
                                 '())))
         (config-files (root-config-files root)))
    (unique
     (filter (lambda (path)
               (changed-source-file? root scan-roots ignored-dirs config-files path))
             (map (cut changed-source-full-path root <>)
                  paths)))))

;; : (-> Root Path Path )
(def (changed-source-full-path root path)
  (path-normalize (source-full-path root path)))

;; : (-> Root Path Path )
(def (source-full-path root path)
  (if (absolute-source-path? path)
    path
    (path-normalize (path-expand path (normalized-root-prefix root)))))

;; : (-> Path Boolean )
(def (absolute-source-path? path)
  (and (string? path)
       (string-prefix? "/" path)))

;; : (-> Root FullPath Path )
(def (relative-path root path)
  (let* ((root* (normalized-root-prefix root))
         (path* (path-normalize path))
         (prefix (string-append root* "/")))
    (if (string-prefix? prefix path*)
      (substring path* (string-length prefix) (string-length path*))
      path*)))

;; : (-> Root Path )
(def (normalized-root-prefix root)
  (strip-trailing-path-separator
   (path-normalize (path-expand "" root))))

;;; Boundary: normalized directory roots may end in `/`; changed-file matching
;;; must compare against one stable root prefix so hidden workspace segments such
;;; as `.run` do not leak into relative paths and trip ignored-directory rules.
;; : (-> Path Path )
(def (strip-trailing-path-separator path)
  (let (last-path-char
        (string-index-right path
                            (lambda (char)
                              (not (char=? char #\/)))))
    (if (and last-path-char
             (< (fx1+ last-path-char) (string-length path)))
      (substring path 0 (fx1+ last-path-char))
      path)))

;; : (-> Root (List String) IgnoredDirs ProjectFiles Path Boolean )
(def (changed-source-file? root scan-roots ignored-dirs config-files path)
  (and (file-exists? path)
       (or (member path config-files)
           (let (relpath (relative-path root path))
             (and (gerbil-source-path? path)
                  (path-under-scan-roots? relpath scan-roots)
                  (not (path-under-ignored-directory? relpath ignored-dirs)))))))

;;; Boundary: scan-root matching is a pure membership predicate over configured roots.
;;; `ormap` plus `cut` keeps each root check independent and avoids reintroducing a manual loop in the changed-file hot path.
;; : (-> Path (List String) Boolean )
(def (path-under-scan-roots? relpath scan-roots)
  (ormap (cut path-under-scan-root? relpath <>)
         scan-roots))

;; : (-> Path String Boolean )
(def (path-under-scan-root? relpath root)
  (let (root* (normalize-relative-rule-path root))
    (or (equal? root* ".")
        (equal? relpath root*)
        (string-prefix? (string-append root* "/") relpath))))

;;; Boundary: ignore matching is a pure membership predicate over configured directory rules.
;;; The combinator form preserves short-circuit behavior while keeping scoped and segment rules in one owner.
;; : (-> Path IgnoredDirs Boolean )
(def (path-under-ignored-directory? relpath ignored-dirs)
  (ormap (cut path-matches-ignored-directory? relpath <>)
         ignored-dirs))

;; : (-> Path String Boolean )
(def (path-matches-ignored-directory? relpath ignored)
  (let (ignored* (normalize-relative-rule-path ignored))
    (or (path-under-scan-root? relpath ignored*)
        (and (path-segment-rule? ignored*)
             (path-has-directory-segment? relpath ignored*)))))

;; : (-> String Boolean )
(def (path-segment-rule? rule)
  (not (string-contains rule "/")))

;;; Boundary: segment matching has three independent path-boundary cases.
;;; Keep the cases as data plus one arity-specialized matcher factory so
;;; ignore-rule repair can extend one case without stacking wrapper lambdas.
;; PathBoundaryCases
(def +path-directory-segment-boundaries+ '(prefix middle suffix))

;; path-directory-segment-boundary-match?
;;   : (-> Symbol String Path Boolean)
;;   | doc m%
;;       `path-directory-segment-boundary-match? boundary segment relpath`
;;       applies one directory-segment boundary rule.
;;     %
(def (path-directory-segment-boundary-match? boundary segment relpath)
  (case boundary
    ((prefix)
     (string-prefix? (string-append segment "/") relpath))
    ((middle)
     (string-contains relpath (string-append "/" segment "/")))
    ((suffix)
     (string-suffix? (string-append "/" segment) relpath))
    (else #f)))

;;; Boundary: `case-lambda` owns the useful factory arities:
;;; one boundary -> reusable binary matcher, boundary+segment -> unary matcher,
;;; and boundary+segment+path -> direct predicate.
;; path-directory-segment-boundary-matcher
;;   : (-> Symbol String (-> Path Boolean))
;;   | type Boundary = (U 'prefix 'middle 'suffix)
;;   | doc m%
;;       `path-directory-segment-boundary-matcher boundary segment` returns a
;;       predicate for one segment-boundary case.
;;     %
(def path-directory-segment-boundary-matcher
  (case-lambda
    ((boundary)
     (lambda (segment relpath)
       (path-directory-segment-boundary-match? boundary segment relpath)))
    ((boundary segment)
     (lambda (relpath)
       (path-directory-segment-boundary-match? boundary segment relpath)))
    ((boundary segment relpath)
     (path-directory-segment-boundary-match? boundary segment relpath))))

;;; Boundary: expose segment matchers as first-class predicates for the public
;;; ignore-rule predicate while delegating arity variants to the factory above.
;; path-directory-segment-matchers
;;   : (-> String (List (-> Path Boolean)))
;;   | doc m%
;;       `path-directory-segment-matchers segment` returns the boundary matchers
;;       for a directory segment in a relative source path.
;;
;;       # Examples
;;
;;       ```scheme
;;       (ormap (lambda (matcher) (matcher "src/cache/db.ss"))
;;              (path-directory-segment-matchers "cache"))
;;       ;; => #t
;;       ```
;;     %
(def (path-directory-segment-matchers segment)
  (map (cut path-directory-segment-boundary-matcher <> segment)
       +path-directory-segment-boundaries+))

;;; Boundary: apply segment matchers through `ormap` to preserve short-circuit
;;; behavior while keeping the individual path cases first-class.
;; : (-> Path String Boolean )
(def (path-has-directory-segment? relpath segment)
  (ormap (lambda (matcher) (matcher relpath))
         (path-directory-segment-matchers segment)))

;;; Package source-scope rules are relative to the workspace. `path-normalize`
;;; expands them to absolute paths, which breaks comparison with parser relpaths.
;; normalize-relative-rule-path
;;   : (-> String String)
;;   | doc m%
;;       `normalize-relative-rule-path path` preserves source-scope rule paths as
;;       workspace-relative match keys while trimming spelling that would make
;;       equivalent rules compare differently.
;;
;;       # Examples
;;
;;       ```scheme
;;       (normalize-relative-rule-path "./src/")
;;       ;; => "src"
;;       ```
;;     %
(def (normalize-relative-rule-path path)
  (let* ((path* (strip-leading-dot-slash path))
         (last-path-char
          (string-index-right path*
                              (lambda (char)
                                (not (char=? char #\/))))))
    (if last-path-char
      (substring path* 0 (fx1+ last-path-char))
      ".")))

;; : (-> String String )
(def (strip-leading-dot-slash path)
  (if (string-prefix? "./" path)
    (substring path 2 (string-length path))
    path))

;; : (-> Policy (List String) )
(def (configured-source-roots policy)
  (let (roots (and policy (source-scope-policy-roots policy)))
    (if (and roots (pair? roots)) roots ["."])))

;; : (-> MaybePackage (List String) )
(def (configured-test-roots package)
  (let* ((policy (and package (project-package-test-directory-policy package)))
         (roots (and policy
                     (test-directory-policy-allowed-directories policy))))
    (if policy
      (or roots '())
      ["t"])))

;; root-config-files
;;   : (-> String (List String))
;;   | doc m%
;;       `root-config-files root` returns existing root-level package/config
;;       files that should participate in project indexing.
;;
;;       # Examples
;;
;;       ```scheme
;;       (root-config-files ".")
;;       ;; => config paths
;;       ```
;;     %
(def (root-config-files root)
  (filter file-exists?
          (map (cut path-expand <> root) +config-files+)))

;; source-directory?
;;   : (-> String Boolean)
;;   | doc m%
;;       `source-directory? path` returns `#t` when `path` exists and is a
;;       directory, returning `#f` for filesystem errors.
;;
;;       # Examples
;;
;;       ```scheme
;;       (source-directory? "src")
;;       ;; => #t
;;       ```
;;     %
(def (source-directory? path)
  (with-catch
   (lambda (_) #f)
   (lambda () (eq? (file-type path) 'directory))))

;; : (-> String Dir IgnoredDirs WalkSourceDirectory )
(def (walk-source-directory root dir ignored-dirs)
  (def (walk dir acc)
    (for/fold (result acc) (entry (sort (directory-files dir) string<?))
      (if (member entry '("." ".."))
        result
        (let (path (path-expand entry dir))
          (cond
           ((and (source-directory? path)
                 (not (ignored-source-directory? root path entry ignored-dirs)))
            (walk path result))
           ((gerbil-source-path? path)
            (cons path result))
           (else result))))))
  (walk dir '()))

;; : (-> String String Entry IgnoredDirs Boolean )
(def (ignored-source-directory? root path entry ignored-dirs)
  (let (relpath
        (normalize-relative-rule-path (relative-path root path)))
    (or (member entry ignored-dirs)
        (member relpath ignored-dirs))))

;; gerbil-source-path?
;;   : (-> String Boolean )
;;   | doc m%
;;       `gerbil-source-path? path` accepts Gerbil source extensions and root
;;       config files that participate in parser-owned project indexing.
;;
;;       # Examples
;;       ```scheme
;;       (gerbil-source-path? "src/parser/core.ss")
;;       ;; => #t
;;       ```
;;     %
(def (gerbil-source-path? path)
  (or (member (path-extension path) +source-extensions+)
      (member (path-strip-directory path) +config-files+)))

;; source-line-count
;;   : (-> String Integer)
;;   | doc m%
;;       `source-line-count path` returns the number of lines in a source file,
;;       or `0` when the file cannot be read.
;;
;;       # Examples
;;
;;       ```scheme
;;       (source-line-count "src/parser/core.ss")
;;       ;; => positive line count
;;       ```
;;     %
(def (source-line-count path)
  (length (read-source-lines path)))

;;; Boundary:
;;; - :std/misc/ports owns file IO; this helper is only the parser's safe
;;;   failure boundary so hot paths can share one read-file-lines result.
;; read-source-lines
;;   : (-> String (List SourceLine))
;;   | doc m%
;;       `read-source-lines path` reads source lines once for parser hot paths,
;;       returning `()` when the file cannot be read.
;;
;;       # Examples
;;
;;       ```scheme
;;       (list? (read-source-lines "src/parser/core.ss"))
;;       ;; => #t
;;       ```
;;     %
(def (read-source-lines path)
  (with-catch
   (lambda (_) '())
   (lambda () (read-file-lines path))))
