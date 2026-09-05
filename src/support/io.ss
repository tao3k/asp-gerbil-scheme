;;; -*- Gerbil -*-
;;; Source-range transport helpers.

(import :gerbil/gambit
        (only-in :asp-gerbil-scheme/src/parser/model
                 definition-path
                 definition-start
                 definition-end)
        (only-in :std/misc/ports read-all-as-string read-file-lines)
        (only-in :std/srfi/13 string-index string-index-right string-prefix?)
        (only-in :std/sugar foldl iota))

(export read-definition-code
        read-definition-with-leading-comments
        read-source-file-purpose-comment
        read-source-text
        write-source-text
        read-selector
        split-selector
        read-line-range
        line-field
        emit-text-line
        emit-field-line)
;; : (-> String Definition ParsedData )
(def (read-definition-code root defn)
  (read-line-range (path-expand (definition-path defn) root)
                   (definition-start defn)
                   (definition-end defn)))
;; : (-> String Definition ParsedData )
(def (read-definition-with-leading-comments root defn)
  (let* ((path (path-expand (definition-path defn) root))
         (start (definition-leading-comment-start path
                                                  (definition-start defn))))
    (read-line-range path start (definition-end defn))))
;; : (-> String Relpath ParsedData )
(def (read-source-file-purpose-comment root relpath)
  (let (comment (source-file-purpose-comment-line
                 (read-file-lines (path-expand relpath root))))
    (if comment
      (string-append comment "\n")
      "")))
;;; Boundary:
;;; - Stop at the first non-header line so purpose comments remain top-scoped.
;;; - Fold state records whether the scan is closed and the discovered comment.
;; : (-> (List SourceFile) String )
(def (source-file-purpose-comment-line lines)
  (cdr
   (foldl (lambda (line state)
            (cond
             ((car state) state)
             ((or (string-prefix? ";;; -*-" line)
                  (string=? line ""))
              state)
             ((string-prefix? ";;;" line)
              (cons #t line))
             (else
              (cons #t #f))))
          (cons #f #f)
          lines)))
;;; Boundary:
;;; - Walk candidate line numbers backward and stop at the first non-comment.
;;; - Fold state keeps the current earliest adjacent comment line and closed flag.
;; : (-> String Integer Integer )
(def (definition-leading-comment-start path start)
  (let* ((lines (read-file-lines path))
         (line-numbers (reverse (iota (fx1- start) 1)))
         (state
          (foldl (lambda (line state)
                   (if (car state)
                     state
                     (let (text (line-at lines line))
                       (if (definition-leading-comment-line? text)
                         (cons #f line)
                         (cons #t (cdr state))))))
                 (cons #f start)
                 line-numbers)))
    (cdr state)))
;; : (-> SourceLine Boolean )
(def (definition-leading-comment-line? text)
  (and text
       (string-prefix? ";;" text)
       (not (string-prefix? ";;; -*-" text))))
;;; Boundary:
;;; - line-at keeps selector lines one-based at the call boundary.
;;; - Guard before list-ref so malformed selectors return #f instead of raising.
;; : (forall (A) (-> (List A) Target (Maybe A)))
(def (line-at lines target)
  (and (fx>= target 1)
       (fx<= target (length lines))
       (list-ref lines (fx1- target))))
;;; Boundary:
;;; - File-only selectors are valid agent-facing source anchors.
;;; - Ranged selectors keep transport small when callers already have line spans.
;; : (-> String String Selector )
(def (read-selector root selector)
  (let* ((parts (split-selector selector))
         (path (car parts))
         (start (cadr parts))
         (end (caddr parts)))
    (if (and start end)
      (read-line-range (path-expand path root) start end)
      (read-source-file (path-expand path root)))))
;;; Boundary:
;;; - A missing colon means path-only, not malformed input.
;;; - Preserve existing path:start-end and path:start:end compatibility.
;; : (-> String Selector )
(def (split-selector selector)
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
;;; Boundary:
;;; - Whole-file reads support natural query selectors such as build.ss.
;;; - Do not force callers to invent a line range for file-level evidence.
;; : (-> String ParsedData )
(def (read-source-file path)
  (foldl (lambda (text out)
           (string-append out text "\n"))
         ""
         (read-file-lines path)))

;; : (-> String String)
(def (read-source-text path)
  (call-with-input-file path read-all-as-string))

;; : (-> String String Void)
(def (write-source-text path text)
  (when (file-exists? path)
    (delete-file path))
  (call-with-output-file path
    (lambda (out)
      (display text out))))
;; read-line-range
;;   : (-> String Integer Integer String)
;;   | doc m%
;;       `read-line-range path start end` reads the inclusive line range from a
;;       source file and preserves trailing newlines in the returned text.
;;
;;       # Examples
;;
;;       ```scheme
;;       (read-line-range "src/core.ss" 1 2)
;;       ;; => selected source text
;;       ```
;;     %
(def (read-line-range path start end)
  (let (lines (read-file-lines path))
    (cdr
     (foldl (lambda (text state)
              (let ((line (car state))
                    (out (cdr state)))
                (cons (fx1+ line)
                      (if (and (>= line start) (<= line end))
                        (string-append out text "\n")
                        out))))
            (cons 1 "")
            lines))))

;; : (forall (A) (-> String A (Pair String A)))
(def (line-field name value)
  (cons name value))

;; : (-> String Unit )
(def (emit-text-line text)
  (displayln text))

;;; Boundary:
;;; - Callers own projection values; this helper owns emission mechanics.
;;; - Keeping display/newline here lets command renderers stay field-list driven.
;; : (forall (A) (-> String (List (Pair String A)) Unit))
;; emit-field-line
;; : (-> String Alist Unit)
(def (emit-field-line prefix fields)
  (display prefix)
  (for-each
   (lambda (field)
     (display " ")
     (display (car field))
     (display "=")
     (display (cdr field)))
   fields)
  (newline))
