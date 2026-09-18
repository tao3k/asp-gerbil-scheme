;;; Formatter core owns byte-preserving source text normalization for the
;;; Gerbil harness; command modules may select files, but they must not
;;; duplicate lexical scanner or suffix ownership rules.
;;; Parser reader facts decide where whitespace may change.
(import :gerbil/gambit
        :asp-gerbil-scheme/src/parser/reader
        :asp-gerbil-scheme/src/utilities/functional)

(export fmt-source-file?
        fmt-format-text
        fmt-format-lines
        fmt-trim-right)

;;; Source suffix allowlist defines the formatter's file boundary; command and
;;; file-walk layers should call fmt-source-file? instead of duplicating suffixes.
;; : (Listof String)
(def +fmt-source-suffixes+
  '(".ss" ".scm" ".sld"))

;;; Reader-state invariant: string and escaped-symbol modes are mutually
;;; exclusive, and block-depth is only meaningful outside both literal modes.

;; fmt-source-file?
;;   : (-> String Boolean)
;;   | doc m%
;;   # Examples
;;   ```scheme
;;   (fmt-source-file? "main.ss")
;;   (fmt-source-file? "README.org")
;;   ;; => #t / #f
;;   ```
;;   Result: true only for Scheme source suffixes owned by formatter core.
(def (fmt-source-file? path)
  (ormap (lambda (suffix)
           (fmt-string-suffix? suffix path))
         +fmt-source-suffixes+))

;; fmt-format-text
;;   : (-> SourceText SourceText)
;;   | doc m%
;;   # Examples
;;   ```scheme
;;   (fmt-format-text "(display 1)   \n")
;;   ;; => "(display 1)\n"
;;   ```
;;   Result: returns newline-terminated source text with safe trailing whitespace removed.
(def (fmt-format-text text)
  (fmt-lines->text
   (fmt-format-lines
    (fmt-split-lines text))))

;; fmt-format-lines
;;   : (-> (List SourceLine) (List SourceLine))
;;   | doc m%
;;   # Examples
;;   ```scheme
;;   (fmt-format-lines ["(display 1)   "])
;;   ;; => ("(display 1)")
;;   ```
;;   Result: returns formatted lines while preserving literal-open line endings.
(def (fmt-format-lines lines)
  (let ((result
         (fold-state
          (lambda (acc line)
            (let* ((state (car acc))
                   (depth (cadr acc))
                   (out (caddr acc))
                   (scan (parser-reader-scan-line/indent line state))
                   (next-state (car scan))
                   (delta (cadr scan))
                   (formatted (fmt-format-line line state depth delta)))
              (list next-state
                    (max 0 (+ depth delta))
                    (cons formatted out))))
          (list (parser-reader-initial-state) 0 [])
          lines)))
    (fmt-drop-trailing-empty-lines (reverse (caddr result)))))

(def (fmt-format-line line state depth delta)
  (let (trimmed (fmt-trim-right line))
    (cond
     ((parser-reader-literal-line? state) trimmed)
     ((string=? (fmt-trim-left trimmed) "") "")
     ((fmt-comment-line? trimmed) trimmed)
     ((> (parser-reader-leading-whitespace-count trimmed) 0) trimmed)
     (else
      (string-append
       (fmt-indent-string
        (* 2 (max 0 (- depth (parser-reader-leading-close-count trimmed)))))
       (fmt-trim-left trimmed))))))

(def (fmt-comment-line? line)
  (let (trimmed (fmt-trim-left line))
    (and (> (string-length trimmed) 0)
         (char=? (string-ref trimmed 0) #\;))))

(def (fmt-trim-left text)
  (let ((len (string-length text)))
    (let loop ((index 0))
      (cond
       ((>= index len) "")
       ((parser-reader-whitespace? (string-ref text index))
        (loop (+ index 1)))
       (else
        (substring text index len))))))

(def (fmt-indent-string width)
  (repeat-char-string #\space width))

;; fmt-trim-right
;;   : (-> String String)
;;   | doc m%
;;   # Examples
;;   ```scheme
;;   (fmt-trim-right "value   ")
;;   ;; => "value"
;;   ```
;;   Result: returns "value" without touching internal whitespace.
(def (fmt-trim-right text)
  (let loop ((index (string-length text)))
    (if (and (> index 0)
             (parser-reader-whitespace? (string-ref text (- index 1))))
      (loop (- index 1))
      (substring text 0 index))))

;;; Final blank-line cleanup: keeps the formatted file to one stable final newline.
;;; | doc m% Removes empty lines from the end after per-line formatting.
;;; # Examples
;;; ["x" "" ""] becomes ["x"].
;;; Result: list of formatted lines without trailing empty lines.
;; : (-> SourceLines SourceLines)
(def (fmt-drop-trailing-empty-lines lines)
  (drop-right-while
   (lambda (line)
     (string=? (fmt-trim-right line) ""))
   lines))

;; fmt-split-lines
;;   : (-> String (List SourceLine))
;;   | rationale: string-split owns traversal; this helper restores formatter EOF semantics.
;;   | doc m%
;;   # Examples
;;   ```scheme
;;   (fmt-split-lines "a\n")
;;   ;; => ("a" "")
;;   ```
;;   Result: returns ("a" "") so a trailing newline stays visible to formatter rules.
(def (fmt-split-lines text)
  (let* ((len (string-length text))
         (parts (string-split text #\newline)))
    (cond
     ((zero? len) [""])
     ((char=? (string-ref text (- len 1)) #\newline)
      (append parts [""]))
     (else parts))))

;;; Join boundary: writes exactly one newline after every retained formatted line.
;;; | doc m% Converts formatted lines back into a source buffer.
;;; # Examples
;;; ["a"] becomes "a\n".
;;; Result: formatted source text.
;; : (-> SourceLines SourceText)
(def (fmt-lines->text lines)
  (if (null? lines)
    ""
    (string-append (string-join lines "\n") "\n")))

;; fmt-string-suffix?
;;   : (-> String String Boolean)
;;   | doc m%
;;   # Examples
;;   ```scheme
;;   (fmt-string-suffix? ".ss" "main.ss")
;;   ;; => #t
;;   ```
;;   Result: true when text ends with the exact suffix.
(def (fmt-string-suffix? suffix text)
  (let ((suffix-len (string-length suffix))
        (text-len (string-length text)))
    (and (>= text-len suffix-len)
         (string=? (substring text (- text-len suffix-len) text-len)
                   suffix))))
