;;; -*- Gerbil -*-
;;; Filesystem, macro-witness, and large-owner fixture writers.

(import :gerbil/gambit
        :std/misc/process)

(export #t)

(def (write-check-changed-project root)
  (let* ((src (string-append root "/src"))
         (changed (string-append src "/changed"))
         (stable (string-append src "/stable")))
    (reset-fixture-root root)
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir changed)
    (ensure-dir stable)
    (write-text (string-append changed "/core.ss")
                ";;; -*- Gerbil -*-\n(package: sample/changed)\n(def changed-value 1)\n")
    (write-text (string-append stable "/core.ss")
                ";;; -*- Gerbil -*-\n(package: sample/stable)\n(def stable-value 1)\n")))
;; : (-> String InitializeGitFixture )
(def (initialize-git-fixture root)
  (run-git root ["init"])
  (run-git root ["config" "user.email" "gerbil-harness@example.invalid"])
  (run-git root ["config" "user.name" "Gerbil Harness Test"])
  (run-git root ["add" "."])
  (run-git root ["commit" "-m" "baseline"]))
;; : (-> String (List String) Unit )
(def (run-git root args)
  (void
   (run-process (cons "git" args)
                directory: root
                stderr-redirection: #t)))
;; : (-> String ResetFixtureRoot )
(def (reset-fixture-root root)
  (when (file-exists? root)
    (void
     (run-process ["rm" "-rf" root]
                  stderr-redirection: #t))))
;; : (-> String String )
(def (write-functional-idiom-control-context-project root)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/orders")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (write-text (string-append owner "/facade.ss")
                ";;; -*- Gerbil -*-\n;;; Orders facade intent.\n(export drain)\n")
    (write-text (string-append owner "/core.ss")
                ";;; -*- Gerbil -*-\n(package: sample/orders)\n(export drain)\n(def (drain xs)\n  (let/cc stop\n    (let loop ((rest xs))\n      (if (null? rest) (stop #f) (loop (cdr rest)))))\n  (try (void) (finally (void))))\n")))
;; : (-> String Allowed Unit )
(def (write-macro-runtime-source-project root allowed?)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/macros"))
         (tests (string-append root "/t")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (ensure-dir tests)
    (write-text (string-append root "/gerbil.pkg")
                "(package: sample/macros)\n")
    (write-text (string-append owner "/core.ss")
                ";;; -*- Gerbil -*-\n(package: sample/macros)\n(defsyntax (with-order stx)\n  #'(void))\n")
    (write-text (string-append tests "/macro-witness-test.ss")
                (string-append
                 ";;; -*- Gerbil -*-\n(import :std/test ../src/macros/core)\n"
                 "(def macro-witness-test\n  (test-suite \"macro witness\"\n"
                 "    (test-case \"expands to runtime behaviour\"\n"
                 "      (with-order)\n"
                 (if allowed? "      (check #t => #t)\n" "")
                 "      )))\n"))))
;; : (-> String Unit)
(def (write-macro-expansion-closure-project root)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/macros"))
         (tests (string-append root "/t")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (ensure-dir tests)
    (write-text (string-append root "/gerbil.pkg")
                "(package: sample/macros)\n")
    (write-text
     (string-append owner "/core.ss")
     (string-append
      ";;; -*- Gerbil -*-\n(package: sample/macros)\n"
      "(defrules private-order-helper () ((_ value) value))\n"
      "(defrules public-with-order () ((_ value) (private-order-helper value)))\n"
      "(defrules private-procedural-helper () ((_ value) value))\n"
      "(defsyntax (public-procedural stx)\n"
      "  (syntax-case stx ()\n"
      "    ((_ value) (syntax (private-procedural-helper value)))))\n"
      "(defrules private-identifier-helper () ((_ value) value))\n"
      "(defsyntax public-identifier\n"
      "  (identifier-rules (id (private-identifier-helper id))))\n"
      "(defrules private-quasi-helper () ((_ value) value))\n"
      "(defsyntax (public-quasi stx)\n"
      "  (syntax-case stx ()\n"
      "    ((_ value)\n"
      "     (quasisyntax\n"
      "      (private-quasi-helper (unsyntax (syntax->datum (syntax value))))))))\n"
      "(defrules cycle-a () ((_ value) (cycle-b value)))\n"
      "(defrules cycle-b () ((_ value) (cycle-a value)))\n"
      "(defrules public-cycle () ((_ value) (cycle-a value)))\n"))
    (write-text
     (string-append tests "/macro-expansion-closure-test.ss")
     (string-append
      ";;; -*- Gerbil -*-\n(import :std/test ../src/macros/core)\n"
      "(def macro-expansion-closure-test\n"
      "  (test-suite \"macro expansion closure\"\n"
      "    (test-case \"public macro witnesses private expansion helper\"\n"
      "      (check (public-with-order 42) => 42)\n"
      "      (check (public-procedural 42) => 42)\n"
      "      (check (public-identifier 42) => 42)\n"
      "      (check (public-quasi 42) => 42)\n"
      "      (check (public-cycle 42) => 42))))\n"))))

;; : (-> String Unit)
(def (write-macro-quoted-data-project root)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/macros"))
         (tests (string-append root "/t")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (ensure-dir tests)
    (write-text (string-append root "/gerbil.pkg")
                "(package: sample/quoted-macros)\n")
    (write-text
     (string-append owner "/core.ss")
     (string-append
      "(defrules quoted-helper () ((_ value) value))\n"
      "(defsyntax (public-quoted-only stx)\n"
      "  (let ((datum '(quoted-helper 42)))\n"
      "    (syntax-case stx () ((_ value) (syntax value)))))\n"))
    (write-text
     (string-append tests "/quoted-macro-test.ss")
     (string-append
      "(import :std/test ../src/macros/core)\n"
      "(def quoted-macro-test\n"
      "  (test-suite \"quoted macro data\"\n"
      "    (test-case \"quoted data is not an expansion edge\"\n"
      "      (check (public-quoted-only 42) => 42))))\n"))))

;; : (-> String Unit)
(def (write-macro-ambiguous-expansion-project root)
  (let* ((src (string-append root "/src"))
         (left (string-append src "/left"))
         (right (string-append src "/right"))
         (tests (string-append root "/t")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir left)
    (ensure-dir right)
    (ensure-dir tests)
    (write-text (string-append root "/gerbil.pkg")
                "(package: sample/ambiguous-macros)\n")
    (write-text
     (string-append left "/core.ss")
     (string-append
      "(defrules shared-helper () ((_ value) value))\n"
      "(defrules public-left () ((_ value) (shared-helper value)))\n"))
    (write-text (string-append right "/core.ss")
                "(defrules shared-helper () ((_ value) value))\n")
    (write-text
     (string-append tests "/ambiguous-macro-test.ss")
     (string-append
      "(import :std/test ../src/left/core)\n"
      "(def ambiguous-macro-test\n"
      "  (test-suite \"ambiguous macro closure\"\n"
      "    (test-case \"ambiguous helper names fail closed\"\n"
      "      (check (public-left 42) => 42))))\n"))))
;; : (-> String (List Path))
(def (write-linked-macro-runtime-source-project root)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/macros"))
         (cases (string-append root "/user-interface"))
         (tests (string-append root "/t")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (ensure-dir cases)
    (ensure-dir tests)
    (write-text (string-append root "/gerbil.pkg")
                "(package: sample/macros)\n")
    (write-text (string-append owner "/core.ss")
                ";;; -*- Gerbil -*-\n(package: sample/macros)\n(defsyntax (with-order stx)\n  #'(void))\n")
    (write-text (string-append cases "/order-case.ss")
                ";;; -*- Gerbil -*-\n(import ../src/macros/core)\n(def order-case (with-order))\n")
    (write-text (string-append tests "/order-case-test.ss")
                (string-append
                 ";;; -*- Gerbil -*-\n(import :std/test)\n"
                 "(load! \"../user-interface/order-case.ss\")\n"
                 "(def order-case-test\n  (test-suite \"order case\"\n"
                 "    (test-case \"observes loaded macro case\"\n"
                 "      (check order-case => #!void))))\n"))
    ["gerbil.pkg"
     "src/macros/core.ss"
     "user-interface/order-case.ss"
     "t/order-case-test.ss"]))
;; : (-> String (List Path))
(def (write-import-linked-macro-runtime-source-project root)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/macros"))
         (cases (string-append root "/user-interface"))
         (tests (string-append root "/t")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (ensure-dir cases)
    (ensure-dir tests)
    (write-text (string-append root "/gerbil.pkg")
                "(package: sample/macros)\n")
    (write-text (string-append owner "/core.ss")
                ";;; -*- Gerbil -*-\n(package: sample/macros)\n(defsyntax (with-order stx)\n  #'(void))\n")
    (write-text (string-append cases "/order-case.ss")
                ";;; -*- Gerbil -*-\n(import ../src/macros/core)\n(export order-case)\n(def order-case (with-order))\n")
    (write-text (string-append cases "/facade.ss")
                ";;; -*- Gerbil -*-\n(import :sample/macros/user-interface/order-case)\n(export order-case)\n")
    (write-text (string-append tests "/order-case-test.ss")
                (string-append
                 ";;; -*- Gerbil -*-\n(import :std/test :sample/macros/user-interface/facade)\n"
                 "(def order-case-test\n  (test-suite \"order case\"\n"
                 "    (test-case \"observes transitively imported macro case\"\n"
                 "      (check order-case => #!void))))\n"))
    ["gerbil.pkg"
     "src/macros/core.ss"
     "user-interface/order-case.ss"
     "user-interface/facade.ss"
     "t/order-case-test.ss"]))
;; : (-> String Declared String )
(def (write-protocol-evidence-project root declared?)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/orders")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (write-text (string-append owner "/protocol.ss")
                (string-append
                 ";;; -*- Gerbil -*-\n(package: sample/orders)\n(import :clan/poo/protocol)\n"
                 (if declared? "(defprotocol <Renderable>)\n" "")
                 "(defgeneric :render)\n"
                 "(defmethod (:render (value <Renderable>)) value)\n"))))
;; : (-> String EnsureDir )
(def (ensure-dir path)
  (with-catch
   (lambda (_) #f)
   (lambda () (create-directory path))))
;; : (-> String SourceLine Unit )
(def (write-text path text)
  (delete-file-if-exists path)
  (call-with-output-file path
    (lambda (port) (display text port))))
;; : (-> String DeleteFileIfExists )
(def (delete-file-if-exists path)
  (with-catch
   (lambda (_) #f)
   (lambda () (delete-file path))))
;; write-large-policy-source
;;   : (-> String OwnerName Unit )
;;   | doc m%
;;       `write-large-policy-source root owner-name` creates a generated
;;       policy source owner under `root/src` for large-file policy fixtures.
;;
;;       # Examples
;;       ```scheme
;;       (write-large-policy-source ".run/policy" "orders")
;;       ;; => writes .run/policy/src/orders/core.ss
;;       ```
;;     %
(def (write-large-policy-source root owner-name)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/" owner-name))
         (source-path (string-append owner "/core.ss")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (with-catch
     (lambda (_) #f)
     (lambda () (delete-file source-path)))
    (call-with-output-file source-path
      (lambda (port)
        (display ";;; -*- Gerbil -*-\n;;; Large source leaf.\n" port)
        (let lp ((index 0))
          (when (fx< index 45)
            (display "(def value" port)
            (display index port)
            (display " " port)
            (display index port)
            (display ")\n" port)
            (lp (fx1+ index))))
        (let lp ((index 0))
          (when (fx< index 610)
            (display ";; padding\n" port)
            (lp (fx1+ index))))))))
;; : (-> String OwnerName Unit )
(def (write-large-policy-test root owner-name)
  (write-padded-policy-test root owner-name 650))
;; write-padded-policy-test
;;   : (-> String OwnerName PaddingLineCount Unit )
;;   | doc m%
;;       `write-padded-policy-test root owner-name padding-line-count` creates
;;       a generated test owner with replay padding for policy-size fixtures.
;;
;;       # Examples
;;       ```scheme
;;       (write-padded-policy-test ".run/policy" "orders" 650)
;;       ;; => writes .run/policy/t/orders-test.ss
;;       ```
;;     %
(def (write-padded-policy-test root owner-name padding-line-count)
  (let* ((test-dir (string-append root "/t"))
         (source-path (string-append test-dir "/" owner-name "-test.ss")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir test-dir)
    (with-catch
     (lambda (_) #f)
     (lambda () (delete-file source-path)))
    (call-with-output-file source-path
      (lambda (port)
        (display ";;; -*- Gerbil -*-\n(import :std/test)\n" port)
        (display "(def " port)
        (display owner-name port)
        (display "-test (test-suite \"" port)
        (display owner-name port)
        (display "\"))\n" port)
        (let lp ((index 0))
          (when (fx< index padding-line-count)
            (display ";; generated replay padding\n" port)
            (lp (fx1+ index))))))))
;; write-ledger-padded-policy-test
;;   : (-> String OwnerName PaddingLineCount Unit )
;;   | doc m%
;;       `write-ledger-padded-policy-test root owner-name padding-line-count`
;;       creates a generated test owner whose first comments model an existing
;;       typed-combinator-style ledger before replay padding.
;;
;;       # Examples
;;       ```scheme
;;       (write-ledger-padded-policy-test ".run/policy" "orders" 200)
;;       ;; => writes .run/policy/t/orders-test.ss
;;       ```
;;     %
(def (write-ledger-padded-policy-test root owner-name padding-line-count)
  (let* ((test-dir (string-append root "/t"))
         (source-path (string-append test-dir "/" owner-name "-test.ss")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir test-dir)
    (delete-file-if-exists source-path)
    (call-with-output-file source-path
      (lambda (port)
        (display ";;; -*- Gerbil -*-\n(import :std/test)\n" port)
        (display ";;; typed-combinator-style ledger\n" port)
        (let lp ((index 0))
          (when (fx< index padding-line-count)
            (display ";; generated replay padding after ledger\n" port)
            (lp (fx1+ index))))))))
;; write-complex-policy-test
;;   : (-> String OwnerName TestCaseCount Unit )
;;   | doc m%
;;       `write-complex-policy-test root owner-name test-case-count` creates a
;;       generated std/test owner with many test cases for complex policy
;;       scenario fixtures.
;;
;;       # Examples
;;       ```scheme
;;       (write-complex-policy-test ".run/policy" "orders" 12)
;;       ;; => writes .run/policy/t/orders-test.ss
;;       ```
;;     %
(def (write-complex-policy-test root owner-name test-case-count)
  (let* ((test-dir (string-append root "/t"))
         (source-path (string-append test-dir "/" owner-name "-test.ss")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir test-dir)
    (with-catch
     (lambda (_) #f)
     (lambda () (delete-file source-path)))
    (call-with-output-file source-path
      (lambda (port)
        (display ";;; -*- Gerbil -*-\n(import :std/test)\n" port)
        (display "(def " port)
        (display owner-name port)
        (display "-test\n  (test-suite \"" port)
        (display owner-name port)
        (display "\"\n" port)
        (let lp ((index 0))
          (when (fx< index test-case-count)
            (display "    (test-case \"case-" port)
            (display index port)
            (display "\" (check " port)
            (display index port)
            (display " => " port)
            (display index port)
            (display "))\n" port)
            (lp (fx1+ index))))
        (display "    ))\n" port)))))
