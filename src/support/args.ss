;;; -*- Gerbil -*-
;;; Boundary:
;;; - module owns an agent-facing surface.
;;; - Keep contracts, evidence, and failure semantics explicit.
;;; Command-line argument helpers.

(import :gerbil/gambit
        (only-in :std/srfi/1 last)
        (only-in :std/srfi/13 string-prefix?))

(export flag?
        option
        options
        positional-args
        executable-argv
        project-root
        drop-project-root
        file-directory?)

;; : (-> (List String) (List String))
(def (executable-argv explicit-args)
  (if (pair? explicit-args)
    explicit-args
    (let (argv (command-line))
      (if (pair? argv) (cdr argv) []))))
;; ConfigConstant
(def +boolean-flags+
  '("--json" "--code" "--names-only" "--changed" "--full" "--check" "--more"
    "--artifact" "--runtime-request-frame-stdin"))
;; ConfigConstant
(def +value-options+
  '("--term" "--query" "--selector" "--workspace" "--from-hook" "--view" "--package"
    "--server-endpoint"
    "--owner"
    "--iterations" "--max-total-ms" "--max-interface-ms" "--whitelist"
    "--topic" "--intent" "--role" "--level" "--rule" "--finding" "--limit"))
;; flag?
;;   : (-> String (List String) Boolean)
;;   | doc m%
;;       `flag? flag args` returns whether the command-line argument list
;;       contains the boolean flag.
;;
;;       # Examples
;;
;;       ```scheme
;;       (flag? "--json" '("--json" "--workspace" "."))
;;       ;; => #t
;;       ```
;;     %
(def (flag? flag args)
  (member flag args))
;; option
;;   : (-> String (List String) (U #f String))
;;   | doc m%
;;       `option flag args` returns the value following `flag`, or `#f` when
;;       the flag is absent.
;;
;;       # Examples
;;
;;       ```scheme
;;       (option "--workspace" '("--workspace" "src"))
;;       ;; => "src"
;;       ```
;;     %
(def (option flag args)
  (match args
    ([] #f)
    ([hd value . rest]
     (if (equal? hd flag) value (option flag (cons value rest))))
    ([_] #f)))
;; options
;;   : (-> String (List String) (List String))
;;   | doc m%
;;       `options flag args` returns every value following repeated occurrences
;;       of `flag`.
;;
;;       # Examples
;;
;;       ```scheme
;;       (options "--term" '("--term" "macro" "--term" "policy"))
;;       ;; => ("macro" "policy")
;;       ```
;;     %
(def (options flag args)
  (match args
    ([] '())
    ([hd value . rest]
     (if (equal? hd flag)
       (cons value (options flag rest))
       (options flag (cons value rest))))
    ([_] '())))
;; positional-args
;;   : (-> (List String) (List String))
;;   | doc m%
;;       `positional-args args` removes known flags and option values while
;;       preserving positional command arguments.
;;
;;       # Examples
;;
;;       ```scheme
;;       (positional-args '("prime" "--workspace" "."))
;;       ;; => ("prime")
;;       ```
;;     %
(def (positional-args args)
  (let (state
        (foldl (lambda (arg state)
                 (let ((out (car state))
                       (skip-next? (cdr state)))
                   (cond
                    (skip-next? (cons out #f))
                    ((member arg +value-options+) (cons out #t))
                    ((or (member arg +boolean-flags+)
                         (string-prefix? "--" arg))
                     (cons out #f))
                    (else (cons (cons arg out) #f)))))
               (cons '() #f)
               args))
    (reverse (car state))))
;; : (-> (List String) ProjectRoot )
(def (project-root args)
  (or (option "--workspace" args)
      (let (pos (positional-args args))
        (if (and (pair? pos) (file-directory? (last pos)))
          (last pos)
          "."))))
;; : (-> (List String) DropProjectRoot )
(def (drop-project-root args)
  (let* ((pos (positional-args args))
         (root? (and (pair? pos) (file-directory? (last pos))))
         (root-index (and root? (length pos))))
    (if root?
      (drop-positional-index args root-index)
      args)))
;; drop-positional-index
;;   : (-> (List String) Integer (List String))
;;   | doc m%
;;       `drop-positional-index args target-index` removes the positional
;;       argument at a one-based positional index without dropping option values.
;;
;;       # Examples
;;
;;       ```scheme
;;       (drop-positional-index '("search" "prime" "--workspace" ".") 2)
;;       ;; => ("search" "--workspace" ".")
;;       ```
;;     %
(def (drop-positional-index args target-index)
  (let (state
        (foldl (lambda (arg state)
                 (let ((out (car state))
                       (index (cadr state))
                       (skip-value? (caddr state)))
                   (cond
                    (skip-value?
                     [(cons arg out) index #f])
                    ((member arg +value-options+)
                     [(cons arg out) index #t])
                    ((or (member arg +boolean-flags+)
                         (string-prefix? "--" arg))
                     [(cons arg out) index #f])
                    (else
                     (let (next-index (fx1+ index))
                       (if (fx= next-index target-index)
                         [out next-index #f]
                         [(cons arg out) next-index #f]))))))
               ['() 0 #f]
               args))
    (reverse (car state))))
;; file-directory?
;;   : (-> String Boolean)
;;   | doc m%
;;       `file-directory? path` returns `#t` when `path` exists and is a
;;       directory, and `#f` for filesystem errors.
;;
;;       # Examples
;;
;;       ```scheme
;;       (file-directory? ".")
;;       ;; => #t
;;       ```
;;     %
(def (file-directory? path)
  (with-catch
   (lambda (_) #f)
   (lambda () (eq? (file-type path) 'directory))))
