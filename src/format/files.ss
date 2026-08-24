;;; -*- Gerbil -*-
;;; Formatter file discovery and write application.

(import :gerbil/gambit
        :gslph/src/format/core
        (only-in :std/misc/path path-expand)
        (only-in :std/sort sort)
        :gslph/src/support/io)

(export fmt-target-files
        fmt-file
        fmt-result-changed?)

(def +fmt-max-explicit-files+ 64)
(def +fmt-max-source-bytes+ (* 1024 1024))

;; fmt-target-files
;;   : (-> String (List String) (List Path))
;;   | result sorted formatter source files under explicit file targets
;;   | doc m%
;;       `fmt-target-files root targets` expands command targets into a stable
;;       list of Gerbil source files. Bulk discovery is Rust-owned.
;;
;;       # Examples
;;
;;       ```scheme
;;       (fmt-target-files "." ["src/core.ss"])
;;       ;; => ["src/core.ss"]
;;       ```
;;     %
(def (fmt-target-files root targets)
  (unless (pair? targets)
    (error "Scheme fmt requires explicit source files; bulk formatting is Rust-owned"))
  (when (> (length targets) +fmt-max-explicit-files+)
    (error "too many Scheme fmt files; bulk formatting is Rust-owned"
           (length targets)))
  (sort (map (lambda (target) (fmt-explicit-source-file root target)) targets)
        string<?))

;; : (-> String String Path)
(def (fmt-explicit-source-file root target)
  (let (path (path-expand target root))
    (unless (and (file-exists? path)
                 (not (eq? (file-type path) 'directory))
                 (fmt-source-file? target))
      (error "fmt target must be an explicit Gerbil source file" target))
    target))

;; fmt-file
;;   : (-> String String Boolean FmtResult)
;;   | result pair of relative path and whether formatting would change content
;;   | doc m%
;;       `fmt-file root relpath check?` applies RS7 formatting to one source
;;       file. In check mode it reports drift without writing.
;;
;;       # Examples
;;
;;       ```scheme
;;       (fmt-file "." "src/core.ss" #t)
;;       ;; => ("src/core.ss" . #f)
;;       ```
;;     %
(def (fmt-file root relpath check?)
  (let* ((path (path-expand relpath root))
         (bytes (file-info-size (file-info path)))
         (_ (when (> bytes +fmt-max-source-bytes+)
              (error "source exceeds Scheme fmt budget" relpath bytes)))
         (original (read-source-text path))
         (formatted (fmt-format-text original))
         (changed? (not (string=? original formatted))))
    (when (and changed? (not check?))
      (write-source-text path formatted))
    (cons relpath changed?)))

;; : (-> FmtResult Boolean)
(def (fmt-result-changed? result)
  (cdr result))
