;;; -*- Gerbil -*-
;;; Documentation-example metadata for typed Scheme comments.

(import :gerbil/runtime/gambit
        (only-in :std/string/misc string-join string-prefix? string-trim)
        (only-in :std/text/pregexp pregexp-match-positions)
        (only-in :std/list/list drop-right last))

(export typed-comment-doc-body-lines
        typed-comment-doc-examples-json
        typed-comment-doc-example-has-expected-result?)

;; : (-> (List SectionLine) (List SectionLine))
(def (typed-comment-doc-body-lines lines)
  (let (body (if (and (pair? lines) (equal? (car lines) "m%"))
              (cdr lines)
              lines))
    (if (and (pair? body) (equal? (last body) "%"))
      (drop-right body 1)
      body)))

;;; Boundary:
;;; - Example parsing is deliberately doc-section local. The parser records
;;;   fenced examples under "# Examples" without trying to execute them.
;; : (-> (List SectionLine) (List Json))
(def (typed-comment-doc-examples-json lines)
  (reverse
   (typed-comment-doc-example-state-examples
    (foldl typed-comment-doc-example-step
           (typed-comment-doc-example-state #f #f "" [] [])
           lines))))

;;; Boundary:
;;; - Example parsing is a fold state, not an executable loop driver.
;;; - The state keeps only doc-section parser facts: heading, fence, language,
;;;   reversed block lines, and reversed examples.
;; : (-> Boolean Boolean String (List SectionLine) (List Json) DocExampleState)
(def (typed-comment-doc-example-state in-examples? in-fence? language block-lines examples)
  [in-examples? in-fence? language block-lines examples])

;; : (-> DocExampleState Boolean)
(def (typed-comment-doc-example-state-in-examples? state)
  (list-ref state 0))

;; : (-> DocExampleState Boolean)
(def (typed-comment-doc-example-state-in-fence? state)
  (list-ref state 1))

;; : (-> DocExampleState String)
(def (typed-comment-doc-example-state-language state)
  (list-ref state 2))

;; : (-> DocExampleState (List SectionLine))
(def (typed-comment-doc-example-state-block-lines state)
  (list-ref state 3))

;; : (-> DocExampleState (List Json))
(def (typed-comment-doc-example-state-examples state)
  (list-ref state 4))

;;; Boundary:
;;; - Each section line produces one immutable state transition.
;;; - Closing a fence is the only transition that appends an example packet.
;; : (-> SectionLine DocExampleState DocExampleState)
(def (typed-comment-doc-example-step line state)
  (let* ((trimmed (string-trim line))
         (in-examples? (typed-comment-doc-example-state-in-examples? state))
         (in-fence? (typed-comment-doc-example-state-in-fence? state))
         (language (typed-comment-doc-example-state-language state))
         (block-lines (typed-comment-doc-example-state-block-lines state))
         (examples (typed-comment-doc-example-state-examples state)))
    (cond
     ((and in-fence? (typed-comment-doc-fence-line? trimmed))
      (typed-comment-doc-example-state
       in-examples?
       #f
       ""
       []
       (typed-comment-doc-cons-example
        language
        (reverse block-lines)
        examples)))
     (in-fence?
      (typed-comment-doc-example-state
       in-examples?
       #t
       language
       (cons line block-lines)
       examples))
     ((typed-comment-doc-examples-heading? trimmed)
      (typed-comment-doc-example-state #t #f "" [] examples))
     ((and in-examples? (typed-comment-doc-fence-line? trimmed))
      (typed-comment-doc-example-state
       #t
       #t
       (typed-comment-doc-fence-language trimmed)
       []
       examples))
     ((and in-examples? (typed-comment-doc-heading-line? trimmed))
      (typed-comment-doc-example-state #f #f "" [] examples))
     (else
      (typed-comment-doc-example-state in-examples? #f "" [] examples)))))

;; : (-> String (List SectionLine) (List Json) (List Json))
(def (typed-comment-doc-cons-example language lines examples)
  (if (null? lines)
    examples
    (cons (typed-comment-doc-example-json language lines) examples)))

;;; Boundary:
;;; - Code/body/expected result fields are split without executing examples.
;;; - This packet is evidence for docs quality, not a test runner.
;; : (-> String (List SectionLine) Json)
(def (typed-comment-doc-example-json language lines)
  (let* ((code-lines
          (filter (lambda (line)
                    (not (typed-comment-doc-result-line? line)))
                  lines))
         (expected-lines
          (filter-map typed-comment-doc-result-text lines)))
    (hash (language language)
          (code (string-join code-lines "\n"))
          (expected (string-join expected-lines "\n"))
          (body (string-join lines "\n"))
          (hasExpectedResult (not (null? expected-lines))))))

;; : (-> Json Boolean)
(def (typed-comment-doc-example-has-expected-result? example)
  (if (hash-get example 'hasExpectedResult) #t #f))

;; : (-> SectionLine Boolean)
(def (typed-comment-doc-examples-heading? line)
  (or (equal? line "# Examples")
      (equal? line "## Examples")))

;; : (-> SectionLine Boolean)
(def (typed-comment-doc-heading-line? line)
  (or (string-prefix? "# " line)
      (string-prefix? "## " line)))

;; : (-> SectionLine Boolean)
(def (typed-comment-doc-fence-line? line)
  (string-prefix? "```" line))

;; : (-> SectionLine String)
(def (typed-comment-doc-fence-language line)
  (string-trim (substring line 3 (string-length line))))

;; : (-> SectionLine Boolean)
(def (typed-comment-doc-result-line? line)
  (let (trimmed (string-trim line))
    (or (string-prefix? ";; =>" trimmed)
        (string-prefix? "# =>" trimmed)
        (string-prefix? "=>" trimmed))))

;; : (-> SectionLine (Maybe String))
(def (typed-comment-doc-result-text line)
  (let* ((trimmed (string-trim line))
         (index (let (matches (pregexp-match-positions "=>" trimmed))
                  (and (pair? matches) (caar matches)))))
    (and index
         (typed-comment-doc-result-line? trimmed)
         (string-trim
          (substring trimmed
                     (+ index 2)
                     (string-length trimmed))))))

