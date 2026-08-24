;;; -*- Gerbil -*-
;;; Boundary:
;;; - test owner records explicit owner-path parsing expectations.
;;; - Keep fixture ownership outside indexed roots.
(import :std/test
        (only-in :gslph/src/commands/guide guide-code-lines)
        :gslph/src/commands/search
        (only-in :gslph/src/commands/search-prime-light
                 search-prime-light-main)
        (only-in :std/srfi/13 string-contains))
(export search-test-part-23)
;; : (-> (List String) String )
(def (search-output args)
  (let* ((status #f)
         (output
          (call-with-output-string
            (lambda (out)
              (parameterize ((current-output-port out))
                (set! status (search-main args)))))))
    (check status => 0)
    output))

(def (prime-light-output args)
  (let* ((status #f)
         (output
          (call-with-output-string
            (lambda (out)
              (parameterize ((current-output-port out))
                (set! status (search-prime-light-main args)))))))
    (check status => 0)
    output))
(def (guide-code-output args)
  (call-with-output-string
    (lambda (out)
      (parameterize ((current-output-port out))
        (guide-code-lines args)))))
;; : (-> OutputPort Fragment Boolean )
(def (contains? output fragment)
  (and (string-contains output fragment) #t))
;; : (-> (List String) Boolean )
(def (search-fails? args)
  (with-catch
   (lambda (_) #t)
   (lambda ()
     (search-main args)
     #f)))
;; : (-> String Unit )
(def (ensure-dir path)
  (with-catch
   (lambda (_) #f)
   (lambda () (create-directory path))))
;; : (-> String SourceLine Unit )
(def (write-text path text)
  (with-catch
   (lambda (_) #f)
   (lambda () (delete-file path)))
  (call-with-output-file path
    (lambda (port) (display text port))))
;; : (-> Unit Path )
(def (write-explicit-owner-fixture)
  (let* ((root ".run/search-explicit-owner")
         (path (string-append root "/outside-owner.ss")))
    (ensure-dir ".run")
    (ensure-dir root)
    (write-text
     path
     ";;; -*- Gerbil -*-\n(def (outside-owner-query value)\n  value)\n(defgeneric (:outside-render self))\n(defclass (<OutsideOwner> Object) (value) transparent: #t)\n(defmethod (:outside-render (self <OutsideOwner>))\n  (.@ self value))\n")
    path))
;; : (-> Unit Path )
(def (write-oversized-owner-fixture)
  (let* ((root ".run/search-oversized-owner")
         (path (string-append root "/oversized.ss")))
    (ensure-dir ".run")
    (ensure-dir root)
    (write-text path (make-string (+ (* 1024 1024) 1) #\x))
    path))
;; SearchTest
;; TestSuite
(def (write-prime-light-fixture)
  (let* ((root ".run/search-prime-light")
         (deep-dir (path-expand "src/generated/deep" root)))
    (ensure-dir root)
    (ensure-dir (path-expand "src" root))
    (ensure-dir (path-expand "src/generated" root))
    (ensure-dir deep-dir)
    (write-text (path-expand "build.ss" root) "(displayln \"fixture\")\n")
    (write-text (path-expand "deep-owner.ss" deep-dir) "(def deep-owner #t)\n")
    root))

(def search-test-part-23
  (test-suite "gerbil scheme harness search part 23"
    (test-case "unsupported search view fails before project collection"
      (check (search-fails? ["query" "--workspace" "."]) => #t))
    (test-case "owner search without explicit path cannot collect workspace"
      (check (search-fails? ["owner" "--workspace" "."]) => #t))
    (test-case "whole-workspace search views fail before Scheme collection"
      (for-each
       (lambda (view)
         (check (search-fails? [view "--workspace" "."]) => #t))
       ["workspace" "prime" "symbol" "import" "structural"
        "lexical" "pipe" "ingest"]))
    (test-case "light prime preview does not walk source directories"
      (let* ((root (write-prime-light-fixture))
             (output (prime-light-output ["prime" "--workspace" root])))
        (check (contains? output "path=build.ss") => #t)
        (check (contains? output "deep-owner.ss") => #f)))
    (test-case "progressive guide resolves descriptors after policy source split"
      (let (output
            (guide-code-output
             ["--code" "--topic" "typed-combinator-style"
              "--more" "--workspace" "."]))
        (check (contains? output "typed-combinator-style-findings") => #t)
        (check (contains? output "functional-idiom-advice-findings") => #t)))
    (test-case "guide topic routes preserve progressive stage semantics"
      (let ((explicit-output
             (guide-code-output
              ["--code" "--topic" "explicit-precise-import"
               "--level" "advanced" "--workspace" "."]))
            (package-output
             (guide-code-output
              ["--code" "--topic" "package-build-canonical-shape"
               "--level" "advanced" "--workspace" "."])))
        (check (contains? explicit-output "explicit-precise-import-finding")
               => #t)
        (check (contains? explicit-output "poo-form-facts-from-form") => #t)
        (check (contains? explicit-output "functional-idiom-advice-findings")
               => #f)
        (check (contains? package-output "package-build-canonical-shape-finding")
               => #t)
        (check (contains? package-output "explicit-precise-import-finding")
               => #t)
        (check (contains? package-output "functional-idiom-advice-findings")
               => #t)))
    (test-case "oversized explicit owner fails before native form parsing"
      (let (path (write-oversized-owner-fixture))
        (check (search-fails? ["owner" path "items" "--view" "seeds"]) => #t)))
    (test-case "owner items parse explicit Gerbil file outside indexed roots"
          (let* ((path (write-explicit-owner-fixture))
                 (output
                  (search-output ["owner" path "items"
                                  "--query"
                                  "outside-owner-query|outside-render|OutsideOwner"
                                  "--view"
                                  "seeds"])))
            (check (contains? output "path=.run/search-explicit-owner/outside-owner.ss") => #t)
            (check (contains? output "kind=def name=outside-owner-query") => #t)
            (check (contains? output "kind=generic name=:outside-render") => #t)
            (check (contains? output "kind=class name=<OutsideOwner>") => #t)))))
