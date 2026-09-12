;;; -*- Gerbil -*-
;;; POO-native extensions for the upstream clan/testing interface.
;;;
;;; This module describes optional test instrumentation.  It deliberately does
;;; not discover files, parse gxtest arguments, or execute suites: `gerbil test`
;;; and clan/testing remain the sole owners of those behaviours.

(import :gerbil/gambit
        (only-in :clan/poo/object .call .cc .o .ref .slot? object?)
        (only-in :clan/poo/debug trace-poo)
        (only-in :std/misc/process run-process)
        (only-in :std/srfi/1 find filter))

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
        testing-interface-runtime-options-for
        testing-interface-command-for
        testing-interface-run-test!
        testing-interface-trace-poo-for
        +testing-memory-profile+
        +testing-performance-profile+
        +testing-debug-trace-profile+
        +testing-serial-resource-profile+
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

(def +asp-testing-interface+
  (testing-interface
   profiles: [+testing-memory-profile+
              +testing-performance-profile+
              +testing-debug-trace-profile+
              +testing-serial-resource-profile+]))

(def (testing-memory-profile-max-heap-mib profile)
  (and (testing-profile-matches? profile 'memory)
       (let (value (.ref profile 'maxHeapMiB))
         (unless (and (integer? value) (> value 0))
           (error "invalid testing memory profile maxHeapMiB" value))
         value)))

(def (testing-interface-runtime-options-for testing test)
  (let (memory
        (find (lambda (profile) (testing-profile-matches? profile 'memory))
              (testing-interface-profiles-for testing test)))
    (if memory
      [(string-append "-:max-heap="
                      (number->string
                       (testing-memory-profile-max-heap-mib memory))
                      "M")]
      [])))

;;; The user-facing contract is the POO profile. This argv projection is the
;;; explicit process boundary required to apply a Gambit heap cap before the
;;; upstream test module is loaded.
;; : (-> TestingInterface Path (List String) (List String))
(def (testing-interface-command-for testing test (arguments []))
  (append ["gerbil"]
          (testing-interface-runtime-options-for testing test)
          ["test"]
          arguments
          [test]))

;;; Delegate one explicit test path to the native Gerbil test command. This
;;; adapter does not discover files, load suites, or construct reports.
;; : (-> TestingInterface Path (List String) Path Value)
(def (testing-interface-run-test! testing test
                                  arguments: (arguments [])
                                  directory: (directory (current-directory)))
  (run-process (testing-interface-command-for testing test arguments)
               directory: directory))

(def (testing-interface-trace-poo-for testing test poo
                                      name: (name 'testing-profile-target))
  (if (find (lambda (profile)
              (testing-profile-matches? profile 'debug-trace))
            (testing-interface-profiles-for testing test))
    (trace-poo poo name)
    poo))
