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
                 init-test-environment!
                 test)
        (only-in :std/cli/multicall
                 define-entry-point
                 set-default-entry-point!)
        (only-in :std/srfi/1 find filter)
        (only-in :std/srfi/13 string-contains string-prefix?))

(export testing-profile
        testing-profile?
        testing-profile-name
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
        testing-interface-trace-poo-for
        testing-discovery-profile-ignore-directories
        testing-interface-ignore-directories-for
        testing-interface-test-file-included?
        testing-interface-test-files
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
                         (not (and (equal? (.ref binding 'test) test)
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
           (if (equal? (.ref binding 'test) test)
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
              +testing-serial-resource-profile+
              +testing-discovery-profile+]))

(def (valid-ignore-directory? directory)
  (and (string? directory)
       (> (string-length directory) 0)
       (not (equal? directory "."))
       (not (equal? directory ".."))
       (not (string-prefix? "/" directory))
       (not (string-prefix? "./" directory))
       (not (string-prefix? "../" directory))
       (not (string-contains directory "/../"))))

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

;;; Preserve clan/testing's command surface and suite execution. The only
;;; extension is selection of its already-discovered files through a POO value.
(defrules init-profiled-test-environment! ()
  ((_ testing)
   (begin
     (init-test-environment!)
     (define-entry-point (asp-profiled-unit-tests)
       (help: "Run clan unit tests through ASP POO profiles"
        getopt: [])
       (apply test (testing-interface-test-files testing "unit-tests.ss")))
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
