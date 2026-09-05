;;; -*- Gerbil -*-
;;; Parser-owned loop driver classification from native call facts.

(import :asp-gerbil-scheme/src/parser/model
        (only-in :std/sugar cut filter ormap))

(export loop-driver-facts-from-source)

(def +reader-driver-callees+ '("read" "read-line" "read-syntax"))
(def +inline-file-reader-callees+ '("call-with-input-file" "path-expand"))
(def +reader-collection-infrastructure-callees+
  '("call-with-input-file" "path-expand" "read" "read-line" "read-syntax"
    "eof-object?" "cons" "append" "reverse" "list" "@list" "null?" "pair?"
    "car" "cdr" "caar" "cadr" "cdar" "cddr" "lambda" "let" "let*" "if"
    "cond" "begin" "loop" "file" "port" "form" "forms" "symbol" "symbols"))
(def +parser-driver-callees+
  '("string-length" "string-ref" "substring" "string->list" "list->string"
    "char=?" "char<?" "char>?" "char-whitespace?" "char-numeric?"
    "char-alphabetic?" "char-upper-case?" "char-lower-case?"))
(def +parser-combinator-callees+
  '("defparser" "parser-parse" "parser-fail" "parser-rewind"
    "raise-parse-error" "make-token"))
(def +state-mutation-callees+
  '("set!" "set-car!" "set-cdr!" "vector-set!" "hash-put!" "hash-remove!"
    "hash-clear!" "table-set!" "table-delete!" ".put!" ".slot-set!"))

(def (loop-driver-facts-from-source relpath calls higher-order-forms control-flow-forms)
  (map (cut loop-driver-fact-from-control-flow relpath calls higher-order-forms <>)
       (filter manual-loop-control-flow? control-flow-forms)))

(def (loop-driver-fact-from-control-flow relpath calls higher-order-forms fact)
  (let* ((driver-kind (loop-driver-kind calls higher-order-forms fact))
         (quality-facets (loop-driver-quality-facets driver-kind)))
    (make-loop-driver-fact
     (control-flow-fact-name fact) "loop-driver" relpath
     (control-flow-fact-start fact) (control-flow-fact-end fact)
     "manual-loop-classification" (or (control-flow-fact-caller fact) "")
     driver-kind (control-flow-fact-binding-count fact)
     (control-flow-fact-body-form-count fact) quality-facets
     (loop-driver-advice driver-kind))))

(def (loop-driver-kind calls higher-order-forms fact)
  (let (caller (control-flow-fact-caller fact))
    (cond
     ((and (caller-has-callee? calls caller +parser-driver-callees+)
           (not (caller-has-callee? calls caller +parser-combinator-callees+)))
      "manual-parser-state-machine")
     ((caller-has-callee? calls caller +state-mutation-callees+)
      "state-driver-candidate")
     ((and (caller-has-callee? calls caller +reader-driver-callees+)
           (caller-has-reader-collection-projection? calls caller))
      "reader-collection-candidate")
     ((and (caller-has-callee? calls caller +reader-driver-callees+)
           (caller-has-callee? calls caller +inline-file-reader-callees+))
      "inline-file-reader-candidate")
     ((caller-has-callee? calls caller +reader-driver-callees+)
      "io-reader-driver")
     ((caller-has-higher-order? higher-order-forms caller)
      "higher-order-boundary")
     ((>= (control-flow-fact-binding-count fact) 4) "state-driver-candidate")
     (else "pure-transform-candidate"))))

(def (loop-driver-quality-facets driver-kind)
  (cond
   ((equal? driver-kind "pure-transform-candidate")
    ["manual-loop-drift" "combinator-candidate"])
   ((equal? driver-kind "manual-parser-state-machine")
    ["manual-parser-state-machine" "parser-combinator-boundary"
     "anti-ai-parser-scaffold"])
   ((equal? driver-kind "reader-collection-candidate")
    ["manual-loop-drift" "combinator-candidate"
     "reader-collection-boundary" "source-form-reader-boundary"])
   ((equal? driver-kind "inline-file-reader-candidate")
    ["manual-loop-drift" "combinator-candidate"
     "inline-file-reader-boundary" "source-form-reader-boundary"])
   ((equal? driver-kind "io-reader-driver")
    ["preserve-named-let-driver" "io-state-boundary"])
   ((equal? driver-kind "higher-order-boundary")
    ["preserve-named-let-driver" "higher-order-boundary"])
   (else ["state-driver-candidate"])))

(def (loop-driver-advice driver-kind)
  (cond
   ((equal? driver-kind "pure-transform-candidate")
    "prefer fold/filter-map/map or predicate helpers if behavior is a pure data transform")
   ((equal? driver-kind "manual-parser-state-machine")
    "replace manual string cursor parsing with a std/parser defparser grammar, parser-fail/parser-rewind, and source-aware parse errors")
   ((equal? driver-kind "reader-collection-candidate")
    "split source/form reading into a reader helper, then use filter-map/map/fold for selection and projection")
   ((equal? driver-kind "io-reader-driver")
    "preserve named let unless a runtime witness proves the IO state machine can be simplified")
   ((equal? driver-kind "higher-order-boundary")
    "preserve explicit loop shape when it is already coupled to a higher-order boundary")
   (else "preserve state-driver shape unless parser facts show a smaller combinator rewrite")))

(def (manual-loop-control-flow? fact)
  (equal? (control-flow-fact-role fact) "manual-loop"))

(def (caller-has-callee? calls caller callees)
  (ormap (lambda (call)
           (and (equal? (or (call-fact-caller call) "") (or caller ""))
                (member (call-fact-callee call) callees)))
         calls))

(def (caller-has-reader-collection-projection? calls caller)
  (ormap (cut reader-collection-projection-call? <> caller) calls))

(def (reader-collection-projection-call? call caller)
  (and (equal? (or (call-fact-caller call) "") (or caller ""))
       (not (equal? (call-fact-callee call) (or caller "")))
       (not (member (call-fact-callee call)
                    +reader-collection-infrastructure-callees+))))

(def (caller-has-higher-order? facts caller)
  (ormap (lambda (fact)
           (equal? (or (higher-order-fact-caller fact) "") (or caller "")))
         facts))
