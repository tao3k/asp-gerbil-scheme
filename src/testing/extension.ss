;;; -*- Gerbil -*-
;;; POO-native extensions for the upstream clan/testing interface.
;;;
;;; This module describes optional test instrumentation and negative discovery
;;; filters. It delegates file discovery and suite execution to clan/testing.

(import :gerbil/gambit
        (only-in :clan/poo/object .call .cc .o .ref .slot? object?)
        (only-in :clan/poo/debug trace-poo)
        (only-in :clan/testing
                 find-test-files
                 %set-test-environment!)
        (only-in :clan/timestamp call-with-timing)
        (only-in :std/cli/multicall
                 define-entry-point
                 define-multicall-main
                 set-default-entry-point!)
        (only-in :std/cli/print-exit silent-exit)
        (only-in :std/source this-source-file)
        (only-in :std/misc/wg make-wg wg-add! wg-wait!)
        (only-in :std/misc/process run-process)
        (only-in :std/srfi/1 drop find filter partition take unfold)
        (only-in :std/srfi/13 string-contains string-prefix?)
        (only-in :std/sugar with-id)
        (only-in ../build-api/core-capacity native-build-core-count))

(export testing-profile
        testing-profile?
        testing-profile-name
        testing-test-selector
        testing-interface
        testing-interface-profile
        testing-interface-profile-names
        testing-interface-profile-enabled?
        testing-interface-map-profile
        testing-interface-profiles-for
        testing-interface-remove-profile
        testing-interface-add-profile
        testing-memory-profile-max-heap-mib
        testing-interface-max-heap-mib-for
        testing-interface-apply-runtime-profile!
        testing-interface-runtime-options-for
        testing-interface-command-for
        testing-interface-run-test!
        testing-interface-trace-poo-for
        testing-discovery-profile-ignore-directories
        testing-interface-ignore-directories-for
        testing-interface-test-file-included?
        testing-interface-test-files
        testing-interface-test-file-serial?
        testing-interface-test-file-batches
        testing-interface-worker-count
        testing-interface-run-test-files!
        init-profiled-test-environment!
        +testing-memory-profile+
        +testing-performance-profile+
        +testing-debug-trace-profile+
        +testing-serial-resource-profile+
        +testing-discovery-profile+
        +asp-testing-interface+)

(def (testing-profile profile-name profile-capability)
  (.o kind: 'testing-profile
      name: profile-name
      capability: profile-capability))

(def (testing-profile? value)
  (and (object? value)
       (.slot? value 'kind)
       (eq? (.ref value 'kind) 'testing-profile)
       (.slot? value 'name)))

(def (testing-profile-name profile)
  (unless (testing-profile? profile)
    (error "not a testing profile" profile))
  (.ref profile 'name))

(def (testing-profile-matches? profile name)
  (eq? (testing-profile-name profile) name))

(def (testing-profile-binding test-path bound-profile)
  (.o kind: 'testing-profile-binding
      test: test-path
      profile: bound-profile))

(def (testing-test-selector relation-value selector-value)
  (unless (and (memq relation-value '(exact contains))
               (string? selector-value)
               (> (string-length selector-value) 0))
    (error "invalid testing test selector" relation-value selector-value))
  (.o kind: 'testing-test-selector
      relation: relation-value
      value: selector-value))

(def (testing-test-selector? value)
  (and (object? value)
       (.slot? value 'kind)
       (eq? (.ref value 'kind) 'testing-test-selector)))

(def (testing-test-selector-equal? left right)
  (cond
   ((and (string? left) (string? right))
    (equal? left right))
   ((and (testing-test-selector? left) (testing-test-selector? right))
    (and (eq? (.ref left 'relation) (.ref right 'relation))
         (equal? (.ref left 'value) (.ref right 'value))))
   (else #f)))

(def (testing-test-selector-matches? selector test)
  (if (string? selector)
    (equal? selector test)
    (begin
      (unless (testing-test-selector? selector)
        (error "not a testing test selector" selector))
      (case (.ref selector 'relation)
        ((exact) (equal? (.ref selector 'value) test))
        ((contains) (and (string-contains test (.ref selector 'value)) #t))
        (else (error "unsupported testing test selector" selector))))))

(def (testing-profile-replace profiles profile)
  (cons profile
        (filter (lambda (current)
                  (not (testing-profile-matches?
                        current
                        (testing-profile-name profile))))
                profiles)))

;;; The methods close over the immutable profile value, so `.call` has the
;;; normal object-oriented shape: `(.call testing .remove 'memory)` while each
;;; update still returns a fresh POO object.
(def (testing-interface profiles: (initial-profiles [])
                        bindings: (initial-bindings []))
  (.o kind: 'testing-interface-extension
      upstream: ':clan/testing
      command: 'gerbil-test
      profiles: initial-profiles
      bindings: initial-bindings
      .remove:
      (lambda (name)
        (testing-interface
         profiles:
         (filter (lambda (profile)
                   (not (testing-profile-matches? profile name)))
                 initial-profiles)
         bindings:
         (filter (lambda (binding)
                   (not (testing-profile-matches?
                         (.ref binding 'profile)
                         name)))
                 initial-bindings)))
      .add:
      (lambda (profile)
        (unless (testing-profile? profile)
          (error "not a testing profile" profile))
        (testing-interface
         profiles:
         (testing-profile-replace initial-profiles profile)
         bindings: initial-bindings))
      .map:
      (lambda (test profile)
        (unless (testing-profile? profile)
          (error "not a testing profile" profile))
        (testing-interface
         profiles: initial-profiles
         bindings:
         (cons (testing-profile-binding test profile)
               (filter (lambda (binding)
                         (not (and (testing-test-selector-equal?
                                    (.ref binding 'test) test)
                                   (testing-profile-matches?
                                    (.ref binding 'profile)
                                    (testing-profile-name profile)))))
                       initial-bindings))))))

(def (testing-interface-profile testing name)
  (find (lambda (profile) (testing-profile-matches? profile name))
        (.ref testing 'profiles)))

(def (testing-interface-profile-names testing)
  (map testing-profile-name (.ref testing 'profiles)))

(def (testing-interface-profile-enabled? testing name)
  (and (testing-interface-profile testing name) #t))

(def (testing-interface-map-profile testing test profile)
  (.call testing .map test profile))

(def (testing-interface-profiles-for testing test)
  (foldl (lambda (binding profiles)
           (if (testing-test-selector-matches? (.ref binding 'test) test)
             (testing-profile-replace profiles (.ref binding 'profile))
             profiles))
         (.ref testing 'profiles)
         (reverse (.ref testing 'bindings))))

(def (testing-interface-remove-profile testing name)
  (.call testing .remove name))

(def (testing-interface-add-profile testing profile)
  (.call testing .add profile))

(def +testing-memory-profile+
  (.cc (testing-profile 'memory 'managed-heap-observation)
       maxHeapMiB: 1024))

(def +testing-performance-profile+
  (.cc (testing-profile 'performance 'machine-observation)
       timingLibrary: ':clan/timestamp
       memoryLibrary: ':asp-gerbil-scheme/src/benchmark/memory
       metrics: '(wall-time cpu-time allocation gc managed-heap)))

(def +testing-debug-trace-profile+
  (.cc (testing-profile 'debug-trace 'poo-method-trace)
       library: ':clan/poo/debug
       operation: 'trace-poo))

(def +testing-serial-resource-profile+
  (testing-profile 'serial-resource 'shared-resource-declaration))

(def +testing-discovery-profile+
  (.cc (testing-profile 'discovery 'clan-test-file-filter)
       ignoreDirectories: []))

(def +asp-testing-interface+
  (testing-interface
   profiles: [+testing-memory-profile+
              +testing-performance-profile+
              +testing-debug-trace-profile+
              +testing-discovery-profile+]))

(def (invalid-ignore-directory-matchers)
  (list (cut equal? <> ".")
        (cut equal? <> "..")
        (cut string-prefix? "/" <>)
        (cut string-prefix? "./" <>)
        (cut string-prefix? "../" <>)
        (cut string-contains <> "/../")))

(def (valid-ignore-directory? directory)
  (and (string? directory)
       (> (string-length directory) 0)
       (not (ormap (lambda (matcher) (matcher directory))
                   (invalid-ignore-directory-matchers)))))

(def (testing-discovery-profile-ignore-directories profile)
  (unless (testing-profile-matches? profile 'discovery)
    (error "not a testing discovery profile" profile))
  (let (directories (.ref profile 'ignoreDirectories))
    (unless (and (list? directories)
                 (andmap valid-ignore-directory? directories))
      (error "invalid testing discovery ignoreDirectories" directories))
    directories))

(def (testing-interface-ignore-directories-for testing test)
  (let (discovery
        (find (lambda (profile)
                (testing-profile-matches? profile 'discovery))
              (testing-interface-profiles-for testing test)))
    (if discovery
      (testing-discovery-profile-ignore-directories discovery)
      [])))

(def (strip-current-directory-prefix path)
  (if (string-prefix? "./" path)
    (substring path 2 (string-length path))
    path))

(def (path-in-directory? path directory)
  (let (relative-path (strip-current-directory-prefix path))
    (or (equal? relative-path directory)
        (string-prefix? (string-append directory "/") relative-path))))

(def (testing-interface-test-file-included? testing test test-file)
  (not (ormap (cut path-in-directory? test-file <>)
              (testing-interface-ignore-directories-for testing test))))

;;; Delegate discovery to clan/testing, then apply only the POO-declared
;;; negative directory boundary. ASP does not maintain a second catalog.
(def (testing-interface-test-files testing test
                                   pkgdir: (pkgdir ".")
                                   regex: (regex "-test.ss$"))
  (filter (cut testing-interface-test-file-included? testing test <>)
          (find-test-files pkgdir regex)))

;; init-profiled-test-environment!
;;   : (-> TestingInterface TestEntryPoint)
;;   | rationale m%
;;       Preserve clan/testing discovery and execution while projecting the
;;       selected POO profiles only at each fresh test-process boundary.
;;     %
;;   | doc m%
;;       Install the normal package unit-test entrypoint after clan discovers
;;       its native test files and the POO discovery profile subtracts ignored
;;       child-package paths. Compatible files are balanced across the native
;;       capacity inherited from `GERBIL_BUILD_CORES`; projects do not declare
;;       a separate batch-size setting.
;;
;;       # Examples
;;       ```scheme
;;       (init-profiled-test-environment! +asp-testing-interface+)
;;       ;; => installs the asp-profiled-unit-tests entrypoint
;;       ```
;;     %
(defrules init-profiled-test-environment! ()
  ((ctx testing)
   (begin
     (def here (this-source-file ctx))
     (with-id ctx (main)
       (define-multicall-main ctx))
     (define-entry-point (asp-profiled-unit-tests)
       (help: "Run clan unit tests through ASP POO profiles"
        getopt: [])
       (%set-test-environment! here)
       (displayln "[asp-testing] phase=entry-ready")
       (force-output)
       (silent-exit
        (let-values (((discovery-nanoseconds test-files)
                      (call-with-timing
                       (lambda ()
                         (testing-interface-test-files
                          testing "unit-tests.ss")))))
          (displayln "[asp-testing] phase=discovery-complete elapsedNs="
                     discovery-nanoseconds
                     " fileCount=" (length test-files))
          (force-output)
          (testing-interface-run-test-files! testing test-files))))
     (set-default-entry-point! 'asp-profiled-unit-tests))))

(def (testing-memory-profile-max-heap-mib profile)
  (and (testing-profile-matches? profile 'memory)
       (let (value (.ref profile 'maxHeapMiB))
         (unless (and (integer? value) (> value 0))
           (error "invalid testing memory profile maxHeapMiB" value))
         value)))

(def (testing-interface-max-heap-mib-for testing test)
  (let (memory
        (find (lambda (profile) (testing-profile-matches? profile 'memory))
              (testing-interface-profiles-for testing test)))
    (and memory (testing-memory-profile-max-heap-mib memory))))

(def (testing-interface-runtime-options-for testing test)
  (let (max-heap-mib (testing-interface-max-heap-mib-for testing test))
    (if max-heap-mib
      [(string-append "-:max-heap="
                      (number->string max-heap-mib)
                      "M")]
      [])))

;;; The public declaration is the POO profile. This is its private projection
;;; at the fresh-process boundary, before the upstream test module is loaded.
(def (testing-interface-command-for testing test (arguments []))
  (append ["gerbil"]
          (testing-interface-runtime-options-for testing test)
          ["test"]
          arguments
          [test]))

(def (testing-interface-run-test! testing test
                                  arguments: (arguments [])
                                  directory: (directory (current-directory)))
  (run-process (testing-interface-command-for testing test arguments)
               directory: directory
               stdout-redirection: #f))

(def (testing-interface-test-file-serial? testing test-file)
  (and (find (lambda (profile)
               (testing-profile-matches? profile 'serial-resource))
             (testing-interface-profiles-for testing test-file))
       #t))

(def (testing-interface-worker-count test-count)
  (min test-count
       (native-build-core-count
        (getenv "GERBIL_BUILD_CORES" #f)
        (##cpu-count))))

;;; Divide one compatible runtime group across the native capacity. The group
;;; widths are derived from file count and GERBIL_BUILD_CORES; projects do not
;;; configure a second batch-size control.
(def (testing-interface-balanced-file-groups test-files worker-count)
  (if (null? test-files)
    []
    (let* ((file-count (length test-files))
           (group-count (min file-count worker-count))
           (base-width (quotient file-count group-count))
           (wide-group-count (modulo file-count group-count)))
      (unfold
       (lambda (state) (= (cdr state) group-count))
       (lambda (state)
         (take (car state)
               (+ base-width (if (< (cdr state) wide-group-count) 1 0))))
       (lambda (state)
         (let (width
               (+ base-width (if (< (cdr state) wide-group-count) 1 0)))
           (cons (drop (car state) width) (+ (cdr state) 1))))
       (cons test-files 0)))))

;; testing-interface-test-file-batches
;;   : (-> TestingInterface (List Path) (List (List Path)))
;;   | rationale derive grouping from GERBIL_BUILD_CORES without a second
;;       project-owned concurrency or batch-size setting
;;   | doc m%
;;       Group files by compatible process options, then distribute each group
;;       across the native core capacity.
;;
;;       # Examples
;;       ```scheme
;;       ;; GERBIL_BUILD_CORES=12
;;       (length
;;        (testing-interface-test-file-batches
;;         +asp-testing-interface+ test-files))
;;       ;; => at most 12
;;       ```
;;     %
(def (testing-interface-test-file-batches testing test-files)
  (let loop ((remaining test-files) (batches-rev []))
    (if (null? remaining)
      (reverse batches-rev)
      (let (options
            (testing-interface-runtime-options-for testing (car remaining)))
        (let-values (((compatible other)
                      (partition
                       (lambda (test-file)
                         (equal? options
                                 (testing-interface-runtime-options-for
                                  testing test-file)))
                       remaining)))
          (let (groups
                (testing-interface-balanced-file-groups
                 compatible
                 (testing-interface-worker-count (length compatible))))
            (loop other (foldl cons batches-rev groups))))))))

(def (testing-interface-command-for-files testing test-files)
  (append ["gerbil"]
          (if (null? test-files)
            []
            (testing-interface-runtime-options-for testing (car test-files)))
          ["test"]
          test-files))

(def (testing-interface-run-test-batch! testing test-files)
  (displayln "[asp-testing] phase=batch-start fileCount="
             (length test-files)
             " firstFile=" (and (pair? test-files) (car test-files)))
  (force-output)
  (let-values (((elapsed-nanoseconds result)
                (call-with-timing
                 (lambda ()
                   (run-process
                    (testing-interface-command-for-files testing test-files)
                    directory: (current-directory)
                    stdout-redirection: #f)))))
    (displayln "[asp-testing] phase=batch-complete elapsedNs="
               elapsed-nanoseconds
               " fileCount=" (length test-files)
               " firstFile=" (and (pair? test-files) (car test-files)))
    (force-output)
    result))

(def (testing-interface-run-test-files! testing test-files)
  (let-values (((serial-files parallel-files)
                (partition (cut testing-interface-test-file-serial?
                                testing <>)
                           test-files)))
    (let* ((parallel-batches
            (testing-interface-test-file-batches testing parallel-files))
           (serial-batches
            (testing-interface-test-file-batches testing serial-files))
           (worker-count
            (testing-interface-worker-count (length parallel-batches)))
           (workgroup (and (> worker-count 0) (make-wg worker-count))))
      (displayln "[asp-testing] phase=batch-dispatch fileCount="
                 (length test-files)
                 " parallelBatchCount=" (length parallel-batches)
                 " serialBatchCount=" (length serial-batches)
                 " workerCount=" worker-count)
      (force-output)
      (when workgroup
        (for-each
         (lambda (test-files)
           (wg-add! workgroup
                    (cut testing-interface-run-test-batch! testing test-files)))
         parallel-batches)
        (wg-wait! workgroup))
      ;; Shared-resource profiles run only after the parallel lane has fully
      ;; quiesced; compatible files retain the same native grouping rule.
      (for-each (cut testing-interface-run-test-batch! testing <>)
                serial-batches)
      (displayln "[asp-testing] phase=all-batches-complete fileCount="
                 (length test-files))
      (force-output)
      #t)))

;;; Apply the selected POO memory profile to the current Gambit runtime.  This
;;; uses the upstream heap API directly; callers never construct startup argv.
;;; Removing the memory profile restores Gambit's unbounded value (zero).
;; : (-> TestingInterface Path Integer)
(def (testing-interface-apply-runtime-profile! testing test)
  (let* ((max-heap-mib
          (testing-interface-max-heap-mib-for testing test))
         (max-heap-bytes
          (if max-heap-mib (* max-heap-mib 1024 1024) 0)))
    (##set-max-heap! max-heap-bytes)
    max-heap-bytes))

(def (testing-interface-trace-poo-for testing test poo
                                      name: (name 'testing-profile-target))
  (if (find (lambda (profile)
              (testing-profile-matches? profile 'debug-trace))
            (testing-interface-profiles-for testing test))
    (trace-poo poo name)
    poo))
