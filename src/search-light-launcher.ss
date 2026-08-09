;;; -*- Gerbil -*-
;;; Native search launcher with fast package/topology seed paths.

(import :gerbil/gambit
        (only-in :gslph/src/commands/search-prime-light
                 search-prime-light-main)
        (only-in :std/misc/process run-process)
        (only-in :std/srfi/13 string-index))

(export main
        try-search-light-main)

(def +search-help+
  "gslph search - Gerbil Scheme native fast search\n\nUsage:\n  gslph search prime [--view seeds] [--workspace PROJECT_ROOT]\n")

(def +query-light-limit+ 40)

;;; Process boundary:
;;; - Fast package/topology seed views stay in native code.
;;; - Other search views fail closed with a granular example instead of
;;;   silently spawning `gxi` and turning search into a slow source load.
;; : (-> (List String) (U Integer #f))
(def (try-search-light-main args)
  (cond
   ((help-argv? args)
    (display +search-help+)
    0)
   ((search-prime-light-argv? args)
    (search-prime-light-main args))
   ((search-rg-query-light-argv? args)
    (emit-search-query-light "rg-query" args))
   ((search-fd-query-light-argv? args)
    (emit-search-query-light "fd-query" args))
   (else
    #f)))

;; : (-> (List String) Integer)
(def (main . args)
  (or (try-search-light-main args)
      (emit-unsupported-native-search args)))

;; : (-> Args Boolean)
(def (help-argv? args)
  (or (null? args)
      (and (null? (cdr args))
           (or (equal? (car args) "-h")
               (equal? (car args) "--help")
               (equal? (car args) "help")))))

;; : (-> Args Boolean )
(def (search-prime-light-argv? args)
  (and (pair? args)
       (equal? (car args) "prime")
       (let (rest (cdr args))
         (and (search-prime-seeds-view? rest)
              (not (arg-present? "--json" rest))))))

;; : (-> Args Boolean )
(def (search-rg-query-light-argv? args)
  (search-query-light-argv? "rg-query" args))

;; : (-> Args Boolean )
(def (search-fd-query-light-argv? args)
  (search-query-light-argv? "fd-query" args))

;; : (-> String Args Boolean )
(def (search-query-light-argv? view args)
  (and (pair? args)
       (equal? (car args) view)
       (pair? (cdr args))
       (not (arg-present? "--json" (cdr args)))))

;; : (-> String Args Integer )
(def (emit-search-query-light view args)
  (let* ((query (search-query-term args))
         (root (or (option-value "--workspace" args) "."))
         (view-name (or (option-value "--view" args) "seeds")))
    (if query
      (begin
        (display "[gerbil-search-light] command=")
        (display view)
        (display " view=")
        (display view-name)
        (display " query=")
        (display query)
        (newline)
        (let (output
              (run-search-query-process root
                                        (if (equal? view "rg-query")
                                          (search-rg-query-command query)
                                          (search-fd-query-command query))))
          (if (string=? output "")
            (display "|note kind=no-output message=\"no matches or search tool unavailable\"\n")
            (emit-limited-output-lines output +query-light-limit+)))
        0)
      (begin
        (display "search query requires a query term after the view name\n"
                 (current-error-port))
        64))))

;; : (-> Args (Maybe String) )
(def (search-query-term args)
  (and (pair? (cdr args))
       (let (candidate (cadr args))
         (and (not (string-option? candidate))
              candidate))))

;; : (-> String Boolean )
(def (string-option? value)
  (and (> (string-length value) 1)
       (string=? (substring value 0 2) "--")))

;; : (-> String (List String) String )
(def (run-search-query-process root command)
  (let (status 0)
    (with-catch
     (lambda (_) "")
     (lambda ()
       (let (output
             (run-process command
                          directory: root
                          stderr-redirection: #t
                          check-status:
                          (lambda (exit-status _settings)
                            (set! status exit-status))))
         (if (or (zero? status) (= status 1)) output ""))))))

;; : (-> String (List String) )
(def (search-rg-query-command query)
  ["rg" "--line-number" "--no-heading" "--color" "never"
   "--max-count" "1" query "."])

;; : (-> String (List String) )
(def (search-fd-query-command query)
  ["fd" "--color" "never" "--type" "f" query "."])

;; emit-output-line
;;   : (-> String Integer Integer Integer)
;;   | doc m%
;;       `emit-output-line` prints one search-hit line and returns the next
;;       source offset to inspect.
;;
;;       # Examples
;;
;;       ```scheme
;;       (emit-output-line "a\nb" 0 3)
;;       ;; => 2
;;       ```
;;     %
(def (emit-output-line output start length)
  (let (line-end (string-index output #\newline start))
    (display "|hit ")
    (if line-end
      (begin
        (display (substring output start line-end))
        (newline)
        (+ line-end 1))
      (begin
        (display (substring output start length))
        (newline)
        length))))

;; emit-limited-output-lines*
;;   : (-> String Integer Integer Integer Integer Integer)
;;   | doc m%
;;       `emit-limited-output-lines*` owns the bounded output recursion for
;;       search-light hits.
;;
;;       # Examples
;;
;;       ```scheme
;;       (emit-limited-output-lines* "a\nb" 3 1 0 0)
;;       ;; => 1
;;       ```
;;     %
(def (emit-limited-output-lines* output length limit start shown)
  (cond
   ((>= start length) shown)
   ((>= shown limit)
    (display "|truncated reason=limit\n")
    shown)
   (else
    (emit-limited-output-lines* output
                                length
                                limit
                                (emit-output-line output start length)
                                (+ shown 1)))))

;; emit-limited-output-lines
;;   : (-> String Integer Integer)
;;   | doc m%
;;       `emit-limited-output-lines` prints at most `limit` search-hit lines and
;;       returns the number of emitted hits.
;;
;;       # Examples
;;
;;       ```scheme
;;       (emit-limited-output-lines "a\nb" 1)
;;       ;; => 1
;;       ```
;;     %
(def (emit-limited-output-lines output limit)
  (let (length (string-length output))
    (emit-limited-output-lines* output length limit 0 0)))

;; : (-> Args Boolean )
(def (search-prime-seeds-view? args)
  (or (equal? (option-value "--view" args) "seeds")
      (arg-present? "seeds" args)))

;; : (-> String Args Boolean )
(def (arg-present? needle args)
  (and (pair? args)
       (or (equal? (car args) needle)
           (arg-present? needle (cdr args)))))

;; : (-> String Args (Maybe String) )
(def (option-value needle args)
  (cond
   ((null? args) #f)
   ((and (pair? (cdr args))
         (equal? (car args) needle))
    (cadr args))
   (else
    (option-value needle (cdr args)))))

;; : (-> (List String) Integer)
(def (emit-unsupported-native-search args)
  (display "gslph search supports native fast seed views only; use `gslph search prime --view seeds --workspace .`.\n"
           (current-error-port))
  64)
