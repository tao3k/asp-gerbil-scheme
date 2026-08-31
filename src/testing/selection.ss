;;; -*- Gerbil -*-
;;; Suite selection predicates for testing projects.

(import :gerbil/gambit
        (only-in :std/srfi/1 find)
        (only-in :std/sugar cut foldl)
        :asp-gerbil-scheme/src/testing/model
        :asp-gerbil-scheme/src/testing/scope
        :asp-gerbil-scheme/src/testing/scenario
        :asp-gerbil-scheme/src/testing/performance)

(export #t)

;; : (-> GxTestSuite Path Boolean)
(def (testing-gxtest-suite-arg? suite arg)
  (and (string? arg)
       (or (equal? arg (testing-suite-name suite))
           (testing-suite-root? suite arg)
           (testing-arg-under-suite-root? suite arg)
           (testing-gxtest-file-in-suite? suite arg))))

;; : (-> Procedure Datum Datum Boolean)
(def (testing-child-name-matches? name-of arg child)
  (equal? arg (name-of child)))

;; : (-> Procedure List Datum Boolean)
(def (testing-any-child-named? name-of children arg)
  (testing-any?
   (cut testing-child-name-matches? name-of arg <>)
   children))

;; : (-> PerformanceSuite Path Boolean)
(def (testing-performance-suite-arg? suite arg)
  (or (equal? arg (testing-suite-name suite))
      (testing-suite-root? suite arg)
      (testing-arg-under-suite-root? suite arg)
      (testing-any-child-named?
       testing-performance-case-name
       (testing-performance-suite-cases suite)
       arg)))

;; : (-> Procedure TestingSuite (List Path) Boolean)
(def (testing-any-suite-arg? suite-arg? suite args)
  (testing-any?
   (cut suite-arg? suite <>)
   args))

;; : (-> TestingSuite Boolean)
(def (testing-gxtest-suite? suite)
  (eq? (testing-object-kind suite) 'gxtest-suite))

;; : (-> GxTestSuite Path Boolean)
(def (testing-gxtest-suite-root-owner? suite arg)
  (and (testing-gxtest-suite? suite)
       (testing-suite-root? suite arg)))

;; : (-> GxTestSuite Path Boolean)
(def (testing-gxtest-suite-file-owner? suite arg)
  (and (testing-gxtest-suite? suite)
       (testing-gxtest-file-in-suite? suite arg)))

;; : (-> List Procedure Path MaybeSuite)
(def (testing-first-suite-matching suites predicate arg)
  (find (lambda (suite)
          (predicate suite arg))
        suites))

;; : (-> List Path MaybeSuite)
(def (testing-owner-suite-for-file suites arg)
  (or (testing-first-suite-matching
       suites
       testing-gxtest-suite-root-owner?
       arg)
      (testing-first-suite-matching
       suites
       testing-gxtest-suite-file-owner?
       arg)))

;; : (-> TestingSuite List Boolean)
(def (testing-suite-name-selected? suite selected)
  (testing-any?
   (lambda (item)
     (equal? (testing-suite-name item)
             (testing-suite-name suite)))
   selected))

;; : (-> List Path List)
(def (testing-append-file-unique files file)
  (if (testing-member-path? file files)
    files
    (append files (list file))))

;; : (-> GxTestSuite List GxTestSuite)
(def (testing-gxtest-suite-with-files suite files)
  (gxtest-suite
   name: (testing-suite-name suite)
   default-root: (testing-suite-default-root suite)
   roots: (testing-suite-roots suite)
   files: files
   batch-size: (testing-suite-batch-size suite)
   gates: (testing-suite-gates suite)
   max-selected-files: (testing-suite-max-selected-files suite)
   max-selected-sources: (testing-suite-max-selected-sources suite)
   max-selected-outputs: (testing-suite-max-selected-outputs suite)
   import->file: (testing-suite-import->file suite)))

;; : (-> List GxTestSuite Path List)
(def (testing-add-file-to-selected-suite selected suite file)
  (cond
   ((null? selected)
    (list (testing-gxtest-suite-with-files suite (list file))))
   ((equal? (testing-suite-name (car selected))
            (testing-suite-name suite))
    (cons (testing-gxtest-suite-with-files
           (car selected)
           (testing-append-file-unique
            (testing-suite-files (car selected))
            file))
          (cdr selected)))
   (else
    (cons (car selected)
          (testing-add-file-to-selected-suite
           (cdr selected)
           suite
           file)))))

;; : (-> List TestingSuite List)
(def (testing-cons-suite-unique selected suite)
  (if (testing-suite-name-selected? suite selected)
    selected
    (cons suite selected)))

(def (testing-direct-file-suite file)
  (gxtest-suite
   name: file
   default-root: file
   files: [file]
   batch-size: 1
   max-selected-files: 1))

;; : (-> List List List)
(def (testing-selected-file-owner-suites suites args)
  (foldl (lambda (arg selected)
           (let (owner (testing-owner-suite-for-file suites arg))
             (if owner
               (testing-add-file-to-selected-suite selected owner arg)
               (if (file-exists? arg)
                 (testing-cons-suite-unique
                  selected
                  (testing-direct-file-suite arg))
                 selected))))
         []
         args))

;; : (-> List List)
(def (testing-non-file-args args)
  (testing-filter (lambda (arg)
                    (not (testing-ss-file-arg? arg)))
                  args))

;; : (-> List List)
(def (testing-file-args args)
  (testing-filter testing-ss-file-arg? args))

;; : (-> List List List)
(def (testing-append-unique-suites left right)
  (reverse
   (foldl (lambda (suite selected)
            (testing-cons-suite-unique selected suite))
          (reverse left)
          right)))

;; : (-> TestingSuite (List Path) Boolean)
(def (testing-suite-selected? suite args)
  (or (null? args)
      (case (testing-object-kind suite)
        ((gxtest-suite)
         (testing-any-suite-arg? testing-gxtest-suite-arg? suite args))
        ((scenario-suite)
         (testing-any-suite-arg? testing-scenario-suite-arg? suite args))
        ((performance-suite)
         (testing-any-suite-arg? testing-performance-suite-arg? suite args))
        (else #f))))

;; : (-> TestingProject (List Path) List)
(def (testing-selected-suites project args)
  (let (suites (testing-project-suites project))
    (if (testing-any? testing-ss-file-arg? args)
      (let* ((named-args (testing-non-file-args args))
             (named-suites
              (if (null? named-args)
                []
                (testing-filter
                 (cut testing-suite-selected? <> named-args)
                 suites)))
             (file-suites
              (testing-selected-file-owner-suites
               suites
               (testing-file-args args))))
        (testing-append-unique-suites named-suites file-suites))
      (testing-filter
       (cut testing-suite-selected? <> args)
       suites))))

;; : (-> TestingProject (List Path) TestingSelection)
(def (testing-select-project project args)
  (let (suites (testing-selected-suites project args))
    (testing-selection
     project: project
     args: args
     suites: suites
     status: (if (or (null? args)
                     (not (null? suites)))
               'ok
               'failed)
     details: (if (or (null? args)
                      (not (null? suites)))
                []
                `((reason . no-selected-suites)
                  (args . ,args))))))
