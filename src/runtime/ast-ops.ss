;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later
;;;
;;; Native Gerbil Scheme AST inspection (`ast-inspect`) and batched reader
;;; soundness oracle (`ast-verify`) for ASP's `agent-semantic-ast` protocol.

(export handle-gerbil-ast-inspect
        handle-gerbil-ast-verify)

(def (mk-obj . pairs)
  (list->hash-table pairs))

(def +gerbil-scheme-syntax-surface+
  (mk-obj
   (cons "lineComment" ";")
   (cons "blockComment" (list "#|" "|#"))
   (cons "delimiterPairs" (list (list "(" ")") (list "[" "]") (list "{" "}")))
   (cons "stringDelimiters" (list "\""))))

;; : (-> String (Values Boolean (Or String #f)))
(def (verify-gerbil-source-with-native-reader source)
  (with-catch
    (lambda (err)
      (values #f (call-with-output-string "" (lambda (p) (display-exception err p)))))
    (lambda ()
      (call-with-input-string source
        (lambda (port)
          (let loop ()
            (let ((form (read port)))
              (unless (eof-object? form)
                (loop))))))
      (values #t #f))))

(def (error-expected-tokens message)
  (let ((out '()))
    (when (or (string-contains-ci message "incomplete")
              (string-contains-ci message "eof")
              (string-contains-ci message "missing"))
      (set! out (list ")" "]" "}")))
    out))

(def (string-contains-ci haystack needle)
  (let ((h (string-downcase haystack))
        (n (string-downcase needle))
        (hlen (string-length haystack))
        (nlen (string-length needle)))
    (if (= nlen 0)
      #t
      (let loop ((i 0))
        (cond
         ((> (+ i nlen) hlen) #f)
         ((string=? (substring h i (+ i nlen)) n) #t)
         (else (loop (+ i 1))))))))

;; Walk UTF-8 bytes of valid Gerbil Scheme source to locate exact [start, end)
;; byte spans and 1-based line numbers of every top-level S-expression form.
(def (scan-top-level-form-spans source)
  (let* ((bytes (string->utf8 source))
         (len (u8vector-length bytes))
         (forms '()))
    (letrec
      ((byte-at (lambda (i) (u8vector-ref bytes i)))
       (ws? (lambda (b) (or (= b 32) (= b 9) (= b 10) (= b 13) (= b 12))))
       (delim? (lambda (b)
                 (or (ws? b) (= b 40) (= b 41) (= b 91) (= b 93) (= b 123) (= b 125)
                     (= b 34) (= b 59))))
       (skip-line-comment
         (lambda (i line)
           (let loop ((k i))
             (cond
              ((>= k len) (values k line))
              ((= (byte-at k) 10) (values (+ k 1) (+ line 1)))
              (else (loop (+ k 1)))))))
       (skip-block-comment
         (lambda (i line)
           (let loop ((k i) (depth 1) (ln line))
             (cond
              ((or (>= k len) (= depth 0)) (values k ln))
              ((and (< (+ k 1) len) (= (byte-at k) 35) (= (byte-at (+ k 1)) 124))
               (loop (+ k 2) (+ depth 1) ln))
              ((and (< (+ k 1) len) (= (byte-at k) 124) (= (byte-at (+ k 1)) 35))
               (loop (+ k 2) (- depth 1) ln))
              ((= (byte-at k) 10) (loop (+ k 1) depth (+ ln 1)))
              (else (loop (+ k 1) depth ln))))))
       (skip-string
         (lambda (i line)
           (let loop ((k i) (ln line))
             (cond
              ((>= k len) (values k ln))
              ((= (byte-at k) 92) ;; backslash escape
               (if (and (< (+ k 1) len) (= (byte-at (+ k 1)) 10))
                 (loop (+ k 2) (+ ln 1))
                 (loop (+ k 2) ln)))
              ((= (byte-at k) 34) (values (+ k 1) ln))
              ((= (byte-at k) 10) (loop (+ k 1) (+ ln 1)))
              (else (loop (+ k 1) ln))))))
       (skip-bar-symbol
         (lambda (i line)
           (let loop ((k i) (ln line))
             (cond
              ((>= k len) (values k ln))
              ((= (byte-at k) 92) (loop (+ k 2) ln))
              ((= (byte-at k) 124) (values (+ k 1) ln))
              ((= (byte-at k) 10) (loop (+ k 1) (+ ln 1)))
              (else (loop (+ k 1) ln))))))
       (skip-ws-and-comments
         (lambda (i line)
           (cond
            ((>= i len) (values i line))
            ((= (byte-at i) 10) (skip-ws-and-comments (+ i 1) (+ line 1)))
            ((ws? (byte-at i)) (skip-ws-and-comments (+ i 1) line))
            ((= (byte-at i) 59) ;; ';'
             (let-values (((ni nln) (skip-line-comment (+ i 1) line)))
               (skip-ws-and-comments ni nln)))
            ((and (< (+ i 1) len) (= (byte-at i) 35) (= (byte-at (+ i 1)) 124)) ;; '#|'
             (let-values (((ni nln) (skip-block-comment (+ i 2) line)))
               (skip-ws-and-comments ni nln)))
            (else (values i line)))))
       (scan-compound
         (lambda (i line)
           (let loop ((k (+ i 1)) (depth 1) (ln line))
             (cond
              ((or (>= k len) (= depth 0)) (values k ln))
              ((= (byte-at k) 10) (loop (+ k 1) depth (+ ln 1)))
              ((= (byte-at k) 59)
               (let-values (((ni nln) (skip-line-comment (+ k 1) ln)))
                 (loop ni depth nln)))
              ((and (< (+ k 1) len) (= (byte-at k) 35) (= (byte-at (+ k 1)) 124))
               (let-values (((ni nln) (skip-block-comment (+ k 2) ln)))
                 (loop ni depth nln)))
              ((= (byte-at k) 34)
               (let-values (((ni nln) (skip-string (+ k 1) ln)))
                 (loop ni depth nln)))
              ((= (byte-at k) 124)
               (let-values (((ni nln) (skip-bar-symbol (+ k 1) ln)))
                 (loop ni depth nln)))
              ((and (< (+ k 1) len) (= (byte-at k) 35) (= (byte-at (+ k 1)) 92)) ;; '#\' char literal
               (if (< (+ k 2) len)
                 (loop (+ k 3) depth (if (= (byte-at (+ k 2)) 10) (+ ln 1) ln))
                 (loop (+ k 2) depth ln)))
              ((or (= (byte-at k) 40) (= (byte-at k) 91) (= (byte-at k) 123))
               (loop (+ k 1) (+ depth 1) ln))
              ((or (= (byte-at k) 41) (= (byte-at k) 93) (= (byte-at k) 125))
               (loop (+ k 1) (- depth 1) ln))
              (else (loop (+ k 1) depth ln))))))
       (scan-atom
         (lambda (i line)
           (cond
            ((= (byte-at i) 34) (skip-string (+ i 1) line))
            ((= (byte-at i) 124) (skip-bar-symbol (+ i 1) line))
            (else
             (let loop ((k i) (ln line))
               (if (or (>= k len) (delim? (byte-at k)))
                 (values k ln)
                 (loop (+ k 1) (if (= (byte-at k) 10) (+ ln 1) ln)))))))))
      (let main ((i 0) (line 1))
        (let-values (((start start-line) (skip-ws-and-comments i line)))
          (if (>= start len)
            (reverse forms)
            (let ((b (byte-at start)))
              (let-values (((end end-line)
                            (cond
                             ((or (= b 40) (= b 91) (= b 123))
                              (scan-compound start start-line))
                             ((and (or (= b 39) (= b 96) (= b 44)) (< (+ start 1) len))
                              (scan-atom (+ start 1) start-line))
                             (else (scan-atom start start-line)))))
                (when (> end start)
                  (let* ((slice (subu8vector bytes start end))
                         (text (utf8->string slice)))
                    (set! forms (cons (list start end start-line text) forms))))
                (main (max (+ start 1) end) end-line)))))))))

(def (symbol-or-head-name datum)
  (cond
   ((symbol? datum) (symbol->string datum))
   ((and (pair? datum) (symbol? (car datum))) (symbol->string (car datum)))
   (else #f)))

(def +scheme-non-call-heads+
  '(quote quasiquote unquote unquote-splicing lambda fn case-lambda
    let let* letrec letrec* let-values let*-values
    if cond case when unless and or begin do set!
    def define def* defvalues defmethod defstruct defclass defsyntax defrules defrule
    import export declare else =>))

(def (collect-scheme-call-targets form acc)
  (cond
   ((not (pair? form)) acc)
   ((memq (car form) '(quote quasiquote)) acc)
   (else
    (let* ((head (car form))
           (acc1 (cond
                  ((and (symbol? head) (not (memq head +scheme-non-call-heads+)))
                   (let ((s (symbol->string head)))
                     (if (member s acc) acc (cons s acc))))
                  ((pair? head) (collect-scheme-call-targets head acc))
                  (else acc))))
      (let loop ((rest (cdr form)) (cur acc1))
        (if (pair? rest)
          (loop (cdr rest) (collect-scheme-call-targets (car rest) cur))
          cur))))))

(def (extract-scheme-import-targets specs)
  (let loop ((rest specs) (acc '()))
    (if (not (pair? rest))
      (reverse acc)
      (let* ((spec (car rest))
             (target
               (cond
                ((symbol? spec) (symbol->string spec))
                ((string? spec) spec)
                ((and (pair? spec) (pair? (cdr spec)) (memq (car spec) '(only-in except-in prefix-in rename-in)))
                 (let ((mod (cadr spec)))
                   (cond ((symbol? mod) (symbol->string mod))
                         ((string? mod) mod)
                         (else #f))))
                (else #f))))
        (loop (cdr rest) (if target (cons target acc) acc))))))

(def (mk-edge src dst rel line)
  (mk-obj (cons "src" src) (cons "dst" dst) (cons "relation" rel) (cons "line" line)))

(def (extract-top-level-edges path line datum)
  (if (not (and (pair? datum) (symbol? (car datum)) (pair? (cdr datum))))
    '()
    (let ((head (car datum))
          (target (cadr datum)))
      (cond
       ((eq? head 'import)
        (map (lambda (mod) (mk-edge path mod "imports" line))
             (extract-scheme-import-targets (cdr datum))))
       ((and (memq head '(def define def* defmethod)) (pair? target) (symbol? (car target)))
        (let ((loc (string-append path "#fn:" (symbol->string (car target))))
              (callees (let loop ((exprs (cddr datum)) (acc '()))
                         (if (pair? exprs)
                           (loop (cdr exprs) (collect-scheme-call-targets (car exprs) acc))
                           (reverse acc)))))
          (map (lambda (callee) (mk-edge loc callee "calls" line)) callees)))
       (else '())))))

(def (classify-top-level-form path start end line text)
  (let ((datum (with-catch (lambda (_) #f)
                 (lambda () (call-with-input-string text read)))))
    (if (not (and (pair? datum) (symbol? (car datum)) (pair? (cdr datum))))
      (values #f '())
      (let* ((head (car datum))
             (target (cadr datum))
             (edges (extract-top-level-edges path line datum))
             (classified
               (cond
                ((memq head '(def define def* defvalues defmethod))
                 (let ((name (symbol-or-head-name target)))
                   (and name
                        (if (pair? target)
                          (list "function" "def" "fn" name)
                          (list "constant" "defconst" "const" name)))))
                ((eq? head '.def)
                 (let ((name (symbol-or-head-name target)))
                   (and name (list "item" "poo_def" "poo" name))))
                ((eq? head 'defstruct)
                 (let ((name (symbol-or-head-name target)))
                   (and name (list "struct" "defstruct" "struct" name))))
                ((eq? head 'defclass)
                 (let ((name (symbol-or-head-name target)))
                   (and name (list "type" "defclass" "class" name))))
                ((memq head '(defsyntax defrules defrule define-syntax))
                 (let ((name (symbol-or-head-name target)))
                   (and name (list "macro" "defsyntax" "macro" name))))
                ((eq? head 'deflanguage)
                 (let ((name (symbol-or-head-name target)))
                   (and name (list "item" "deflanguage" "grammar" name))))
                ((eq? head 'import)
                 (list "import" "import" "import" (string-append "import_line_" (number->string line))))
                (else #f))))
        (if (not classified)
          (values #f edges)
          (let ((kind (list-ref classified 0))
                (lang-kind (list-ref classified 1))
                (tag (list-ref classified 2))
                (name (list-ref classified 3))
                (span (mk-obj (cons "start" start) (cons "end" end))))
            (values
              (mk-obj
               (cons "locator" (string-append path "#" tag ":" name))
               (cons "kind" kind)
               (cons "languageKind" lang-kind)
               (cons "name" name)
               (cons "line" line)
               (cons "outerSpan" span)
               (cons "innerSpan" span)
               (cons "attrs" '()))
              edges)))))))

(def (handle-gerbil-ast-inspect payload)
  (let* ((path (or (hash-ref payload "path" #f) "<memory>"))
         (source (or (hash-ref payload "sourceUtf8" #f) "")))
    (let-values (((ok? err-msg) (verify-gerbil-source-with-native-reader source)))
      (if (not ok?)
        (mk-obj
         (cons "accepted" #f)
         (cons "nodes" '())
         (cons "edges" '())
         (cons "diagnostics"
          (list (mk-obj (cons "byteStart" (u8vector-length (string->utf8 source)))
                        (cons "byteEnd" (u8vector-length (string->utf8 source)))
                        (cons "message" (or err-msg "Gerbil Scheme reader error"))
                        (cons "expectedTokens" (error-expected-tokens (or err-msg ""))))))
         (cons "syntaxSurface" +gerbil-scheme-syntax-surface+))
        (let ((spans (scan-top-level-form-spans source))
              (nodes '())
              (edges '()))
          (for-each
           (lambda (entry)
             (let-values (((node form-edges)
                           (classify-top-level-form
                             path
                             (list-ref entry 0)
                             (list-ref entry 1)
                             (list-ref entry 2)
                             (list-ref entry 3))))
               (when node (set! nodes (cons node nodes)))
               (for-each (lambda (e) (set! edges (cons e edges))) form-edges)))
           spans)
          (mk-obj
           (cons "accepted" #t)
           (cons "nodes" (reverse nodes))
           (cons "edges" (reverse edges))
           (cons "diagnostics" '())
           (cons "syntaxSurface" +gerbil-scheme-syntax-surface+)))))))

(def (handle-gerbil-ast-verify payload)
  (let* ((raw-cands (hash-ref payload "candidates" '()))
         (cands (cond
                 ((vector? raw-cands) (vector->list raw-cands))
                 ((list? raw-cands) raw-cands)
                 (else '())))
         (results
           (map (lambda (cand)
                  (let* ((cand-id (or (hash-ref cand "candidateId" #f) ""))
                         (source (or (hash-ref cand "sourceUtf8" #f) ""))
                         (byte-len (u8vector-length (string->utf8 source))))
                    (let-values (((ok? err-msg) (verify-gerbil-source-with-native-reader source)))
                      (if ok?
                        (mk-obj (cons "candidateId" cand-id)
                                (cons "accepted" #t)
                                (cons "diagnostics" '()))
                        (mk-obj (cons "candidateId" cand-id)
                                (cons "accepted" #f)
                                (cons "diagnostics"
                                 (list (mk-obj (cons "byteStart" byte-len)
                                               (cons "byteEnd" byte-len)
                                               (cons "message" (or err-msg "Gerbil Scheme reader error"))
                                               (cons "expectedTokens"
                                                (error-expected-tokens (or err-msg "")))))))))))
                cands)))
    (mk-obj (cons "results" results))))
