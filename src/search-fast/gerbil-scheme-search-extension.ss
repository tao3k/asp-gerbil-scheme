;;; -*- Gerbil -*-
;;; Fast extension search packet emitter for Gerbil POO registration.
;;; Keeps startup dependency-light so extension lookup stays below agent latency budget.
;;; Leaves protocol rows explicit because agents depend on stable line-oriented fields.
(import :gerbil/gambit
        (only-in :std/srfi/13 string-join string-suffix?))
(export main)

;; : (-> Unit String )
(def +poo-dependency+ "git.cons.io/mighty-gerbils/gerbil-poo")
;; : (-> Unit String )
(def +capabilities+
  "object-system,metaobject-protocol,protocols,policy-protocol,macro-governance,user-override-witness,inherited-gerbil-utils,higher-order-control,typed-combinator-style,pattern-inheritance")

;; : (-> (List String) Unit )
(def (emit . parts)
  (for-each display parts)
  (newline))

;; : (-> String Boolean )
(def (option-with-value? arg)
  (or (equal? arg "--view")
      (equal? arg "--workspace")))

;; : (-> (List String) (List String) (List String) )
(def (collect-positional-args rest out)
  (cond
   ((null? rest) (reverse out))
   ((option-with-value? (car rest))
    (collect-positional-args (if (pair? (cdr rest)) (cddr rest) '()) out))
   ((equal? (car rest) "--json")
    (collect-positional-args (cdr rest) out))
   (else (collect-positional-args (cdr rest) (cons (car rest) out)))))

;; : (-> (List String) (List String) )
(def (positional-args args)
  (collect-positional-args args '()))

;; : (-> String Boolean )
(def (identity-token? term)
  (or (equal? term "poo")
      (equal? term "gerbil")
      (equal? term "gerbil-poo")
      (equal? term +poo-dependency+)))

;; : (-> MaybePathString Boolean )
(def (source-script-path? value)
  (and (string? value)
       (string-suffix? ".ss" value)))

;; : (-> Unit (List String) )
(def (entry-args)
  (let (args (command-line))
    (if (and (pair? args)
             (pair? (cdr args))
             (source-script-path? (cadr args)))
      (cddr args)
      (cdr args))))

;;; Boundary: extension identity tokens are stripped before composing the next query.
;; : (-> (List String) String )
(def (focus terms)
  (let (rest (filter (lambda (term) (not (identity-token? term))) terms))
    (if (null? rest) "usage" (string-join rest " "))))

;;; Boundary: main owns the line-oriented packet contract for extension discovery.
;; : (-> (List String) Integer )
(def (main . args)
  (let* ((raw-extension-args
          (if (and (pair? args)
                   (equal? (car args) "extension"))
            (cdr args)
            args))
         (terms (positional-args raw-extension-args))
         (query (if (null? terms) "-" (string-join terms " ")))
         (next-focus (focus terms)))
    (emit "[gerbil-search-extension] query=" query
          " matches=1 evidenceGrade=fact authority=ecosystem-extension")
    (emit "|extension name=poo activation=gerbil-poo://"
          " packageManager=gxpkg dependencyMode=registered"
          " package=gerbil-poo://registry"
          " dependencies=" +poo-dependency+
          " capabilities=" +capabilities+)
    (emit "|agentAction action=follow-next"
          " registeredKnowledge=gerbil-poo://"
          " notProjectActivation=true"
          " missingLocalAction=install-package-before-repository-fallback"
          " fallback=repository-source-after-install-check"
          " command=\"asp gerbil-scheme search pattern gerbil-poo "
          next-focus
          " --view seeds\"")
    (emit "|sourceLookup order=local-source-before-git"
          " missingLocalAction=install-package-before-repository-fallback"
          " fallbackPolicy=repository-source-after-install-check"
          " localRootHint=~/.gerbil"
          " localPackage=" +poo-dependency+
          " localStatus=probe-first"
          " localMissingAction=install-package-before-repository-fallback"
          " installHint=\"gxpkg install " +poo-dependency+ "\""
          " repository=" +poo-dependency+
          " repositoryUrl=https://git.cons.io/mighty-gerbils/gerbil-poo"
          " indexOwner=asp-server"
          " indexBackend=rust-sql"
          " indexPackageManager=gxpkg")
    (emit "next=search pattern gerbil-poo " next-focus)
    0))

(exit (apply main (entry-args)))
