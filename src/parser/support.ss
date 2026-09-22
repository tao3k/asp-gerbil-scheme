;;; -*- Gerbil -*-
;;; Shared parser support helpers for Gerbil syntax facts.

(import :gerbil/expander
        :gerbil/runtime/gambit
        )

(export flatten
        flatten-with-pairs
        tree-contains-symbol?
        datum-list-items
        stx-list-items
	        list-safe-cadr
	        list-safe-caddr
	        metadata-head?
	        form-datum-head
	        form-metadata-value
	        form-next-rest
	        safe-cadr
        safe-caddr
        safe-cdr
        safe-cddr
        safe-cdddr
        datum->string
        source-start-line
        source-end-line
        exception->string)
;; : (-> Obj Flatten )
(def (flatten obj)
  (let ((todo (list obj))
        (out '()))
    (while (pair? todo)
      (let ((item (car todo))
            (rest (cdr todo)))
        (cond
         ((null? item)
          (set! todo rest))
         ((pair? item)
          (set! todo (cons (car item) (cons (cdr item) rest))))
         (else
          (set! out (cons item out))
          (set! todo rest)))))
    (reverse out)))
;; : (-> Obj FlattenWithPairs )
(def (flatten-with-pairs obj)
  (let ((todo (list obj))
        (out '()))
    (while (pair? todo)
      (let ((item (car todo))
            (rest (cdr todo)))
        (cond
         ((null? item)
          (set! todo rest))
         ((pair? item)
          (set! out (cons item out))
          (set! todo (cons (car item) (cons (cdr item) rest))))
         (else
          (set! out (cons item out))
          (set! todo rest)))))
    (reverse out)))
;; : (-> Obj Symbol Boolean )
(def (tree-contains-symbol? obj symbol)
  (ormap (cut eq? <> symbol)
         (flatten obj)))
;; datum-list-items
;;   : (-> Obj (List Obj))
;;   | doc m%
;;       `datum-list-items obj` returns the proper-list prefix of a datum while
;;       preserving item order.
;;
;;       # Examples
;;
;;       ```scheme
;;       (datum-list-items '(a b . c))
;;       ;; => (a b)
;;       ```
;;     %
(def (datum-list-items obj)
  (let ((rest obj)
        (out '()))
    (while (pair? rest)
      (set! out (cons (car rest) out))
      (set! rest (cdr rest)))
    (reverse out)))
;; : (-> Obj Integer )
(def (stx-list-items obj)
  (cond
   ((not obj) '())
   ((stx-null? obj) '())
   ((stx-pair? obj)
    (cons (stx-car obj) (stx-list-items (stx-cdr obj))))
   (else '())))
;; list-safe-cadr
;;   : (forall (a) (-> (List a) (U #f a)))
;;   | doc m%
;;       `list-safe-cadr items` returns the second item of a list, or `#f` when
;;       the list is too short.
;;
;;       # Examples
;;
;;       ```scheme
;;       (list-safe-cadr '(a b c))
;;       ;; => b
;;       ```
;;     %
;; list-safe-cadr
;; : (forall (a) (-> [a] (Maybe a)))
;; : (-> List (Maybe Datum))
(def (list-safe-cadr items)
  (match items
    ([_ second . _] second)
    (else #f)))
;; list-safe-caddr
;;   : (forall (a) (-> (List a) (U #f a)))
;;   | doc m%
;;       `list-safe-caddr items` returns the third item of a list, or `#f` when
;;       the list is too short.
;;
;;       # Examples
;;
;;       ```scheme
;;       (list-safe-caddr '(a b c))
;;       ;; => c
;;       ```
;;     %
;; list-safe-caddr
;; : (forall (a) (-> [a] (Maybe a)))
;; : (-> List (Maybe Datum))
(def (list-safe-caddr items)
  (match items
    ([_ _ third . _] third)
    (else #f)))
;; : (-> Head Boolean )
(def (metadata-head? head)
  (member head '(package package: prelude: namespace: import export include)))
;; : (-> Datum Head )
(def (form-datum-head datum)
  (cond
   ((pair? datum) (car datum))
   ((metadata-atom-datum? datum) datum)
   (else #f)))
;; : (-> Datum Boolean )
(def (metadata-atom-datum? datum)
  (member datum '(package: prelude: namespace:)))
;; : (-> Datum Rest MetadataValue )
(def (form-metadata-value datum rest)
  (cond
   ((pair? datum) (safe-cadr datum))
   ((and (metadata-atom-datum? datum) (pair? rest))
    (syntax->datum (car rest)))
   (else #f)))
;; : (-> Datum Rest Rest )
(def (form-next-rest datum rest)
  (if (and (metadata-atom-datum? datum) (pair? (cdr rest)))
    (cddr rest)
    (cdr rest)))
;; : (-> Obj SafeCadr )
(def (safe-cadr obj)
  (match obj
    ([_ second . _] second)
    (else #f)))
;; : (-> Obj SafeCaddr )
(def (safe-caddr obj)
  (match obj
    ([_ _ third . _] third)
    (else #f)))
;; : (-> Obj SafeCdr )
(def (safe-cdr obj)
  (if (pair? obj) (cdr obj) '()))
;; : (-> Obj SafeCddr )
(def (safe-cddr obj)
  (safe-cdr (safe-cdr obj)))
;; : (-> Obj SafeCdddr )
(def (safe-cdddr obj)
  (safe-cdr (safe-cddr obj)))
;; datum->string
;;   : (-> Obj (U #f String))
;;   | doc m%
;;       `datum->string obj` converts strings, symbols, keywords, and printable
;;       datums into source-facing string values.
;;
;;       # Examples
;;
;;       ```scheme
;;       (datum->string 'alpha)
;;       ;; => "alpha"
;;       ```
;;     %
(def (datum->string obj)
  (cond
   ((not obj) #f)
   ((string? obj) obj)
   ((symbol? obj) (symbol->string obj))
   ((keyword? obj) (string-append (keyword->string obj) ":"))
   (else (call-with-output-string "" (cut display obj <>)))))
;; : (-> Loc Integer )
(def (source-start-line loc)
  (if (##locat? loc)
    (fx1+ (##filepos-line (##position->filepos (##locat-start-position loc))))
    1))
;; : (-> Loc Integer )
(def (source-end-line loc)
  (if (##locat? loc)
    (fx1+ (##filepos-line (##position->filepos (##locat-end-position loc))))
    1))
;; exception->string
;;   : (-> Exn String)
;;   | doc m%
;;       `exception->string exn` renders an exception without dumping a stack
;;       trace into parser diagnostics.
;;
;;       # Examples
;;
;;       ```scheme
;;       (exception->string exn)
;;       ;; => diagnostic text
;;       ```
;;     %
(def (exception->string exn)
  (parameterize ((dump-stack-trace? #f))
    (call-with-output-string "" (cut display-exception exn <>))))
