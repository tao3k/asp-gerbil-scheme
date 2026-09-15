;;; -*- Gerbil -*-
;;; Parser regression for calls nested in native gerbil-poo definitions.

(import :gerbil/gambit
        :std/test
        :asp-gerbil-scheme/src/parser/facade
        (only-in :asp-gerbil-scheme/src/policy/agent-basic
                 top-level-executable-findings))

(export poo-definition-caller-test)

;; : (-> Path Void )
(def (ensure-directory path)
  (unless (file-exists? path)
    (create-directory path)))

;; : (-> Path String Void )
(def (write-source path source)
  (call-with-output-file path
    (lambda (port)
      (display source port))))

;; : (-> Root Void )
(def (write-poo-definition-project root)
  (let ((src (string-append root "/src")))
    (ensure-directory ".run")
    (ensure-directory root)
    (ensure-directory src)
    (write-source (string-append root "/gerbil.pkg")
                  "(package: sample/poo)\n")
    (write-source
     (string-append src "/objects.ss")
     ";;; -*- Gerbil -*-\n(package: sample/poo)\n(import :clan/poo/object)\n(.def Sample.\n  values: (list 1 2)\n  metadata: (hash (role 'sample)))\n")))

;; : (-> ProjectIndex SourceFile )
(def (objects-source-file index)
  (find (lambda (file)
          (equal? (source-file-path file) "src/objects.ss"))
        (project-index-files index)))

(def poo-definition-caller-test
  (test-suite "poo definition caller ownership"
    (test-case ".def nested calls belong to the prototype definition"
      (let* ((root ".run/poo-definition-caller")
             (_ (write-poo-definition-project root))
             (index (collect-project root))
             (file (objects-source-file index))
             (callers (map call-fact-caller (source-file-calls file))))
        (check (pair? callers) => #t)
        (check (andmap (lambda (caller) (equal? caller "Sample.")) callers)
               => #t)
        (check (top-level-executable-findings index) => [])))))
