;;; -*- Gerbil -*-
;;; Prepared-source admission trampoline for the source-admission Profile.

(import (only-in :clan/poo/object .call .o .ref .slot?)
        (only-in :std/test test-suite test-case)
        (only-in :std/srfi/1 append-map filter filter-map find foldl unfold)
        (only-in :std/srfi/13 string-prefix?)
        (only-in :std/sugar cut)
        (only-in ./extension
                 testing-import-footprint-profile?
                 testing-interface-profile-enabled?
                 testing-interface-profiles-for)
        (only-in ../build-api/native-import-closure
                 call-with-asp-gerbil-scheme-prepared-source-graph)
        (only-in ../build-api/resident-import-footprint
                 asp-gerbil-scheme-resident-import-footprints))

(export testing-interface-call-with-prepared-source-graph
        testing-interface-admit-resident-import-footprints!
        testing-interface-prepared-source-admission-suite)

(def (module-id->string id)
  (cond
   ((symbol? id) (symbol->string id))
   ((string? id) id)
   (else (error "invalid resident module id" id))))

(def (module-id-ignored? id prefixes)
  (let (name (module-id->string id))
    (and (find (lambda (prefix) (string-prefix? prefix name)) prefixes) #t)))

(def (unique-module-ids ids)
  (reverse
   (foldl (lambda (id unique-rev)
            (if (member id unique-rev) unique-rev (cons id unique-rev)))
          [] ids)))

(def (shared-module-ids left right)
  (filter (lambda (id) (member id right)) left))

(def (resident-footprint-profile-for testing test)
  (find testing-import-footprint-profile?
        (testing-interface-profiles-for testing test)))

(def (resident-import-footprints roots ignored-prefixes)
  (let loop-roots ((pending roots) (seen-owners []) (footprints-rev []))
    (if (null? pending)
      (reverse footprints-rev)
      (let loop-footprints
           ((pending-footprints
             (asp-gerbil-scheme-resident-import-footprints (car pending)))
            (seen seen-owners)
            (result footprints-rev))
        (if (null? pending-footprints)
          (loop-roots (cdr pending) seen result)
          (let* ((footprint (car pending-footprints))
                 (owner (car footprint))
                 (closure
                  (unique-module-ids
                   (filter (lambda (id)
                             (not (module-id-ignored? id ignored-prefixes)))
                           (cdr footprint)))))
            (if (member owner seen)
              (loop-footprints (cdr pending-footprints) seen result)
              (loop-footprints
               (cdr pending-footprints)
               (cons owner seen)
               (cons (cons owner closure) result)))))))))

(def (resident-import-overlap left right large-threshold)
  (let ((left-closure (cdr left))
        (right-closure (cdr right)))
    (and (>= (length left-closure) large-threshold)
         (>= (length right-closure) large-threshold)
         (let (shared (shared-module-ids left-closure right-closure))
           (.o leftOwner: (car left)
               rightOwner: (car right)
               leftModuleCount: (length left-closure)
               rightModuleCount: (length right-closure)
               sharedModules: shared
               sharedModuleCount: (length shared))))))

(def (resident-import-overlaps footprints large-threshold)
  (append-map
   (lambda (suffix)
     (filter-map
      (cut resident-import-overlap (car suffix) <> large-threshold)
      (cdr suffix)))
   (unfold null? values cdr footprints)))

;;; Authoritative duplicate-large-closure admission.  All closure membership
;;; comes from Gerbil's __module-registry after gxtest has prepared the test;
;;; this path never reads source, expands a module, or invokes import-module.
(def (testing-interface-admit-resident-import-footprints!
      testing test-name root-paths)
  (alet (profile (resident-footprint-profile-for testing test-name))
    (unless (testing-import-footprint-profile? profile)
      (error "invalid testing import footprint profile" profile))
    (let* ((large-threshold (.ref profile 'largeClosureModuleCount))
           (maximum-shared (.ref profile 'maxSharedClosureModules))
           (footprints
            (resident-import-footprints
             root-paths (.ref profile 'ignoredModulePrefixes)))
           (overlap-values
            (resident-import-overlaps footprints large-threshold))
           (violation-values
            (filter (lambda (overlap)
                      (> (.ref overlap 'sharedModuleCount) maximum-shared))
                    overlap-values))
           (admitted-value? (null? violation-values))
           (receipt
            (.o kind: 'testing-resident-import-footprint-receipt
                test: test-name
                roots: root-paths
                footprints:
                (map (lambda (footprint)
                       (.o owner: (car footprint)
                           moduleCount: (length (cdr footprint))
                           modules: (cdr footprint)))
                     footprints)
                overlaps: overlap-values
                violations: violation-values
                largeClosureModuleCount: large-threshold
                maxSharedClosureModules: maximum-shared
                admitted?: admitted-value?
                code: (if admitted-value?
                        'testing-resident-import-footprints-admitted
                        'testing-duplicate-large-import-closure))))
      (when (and (not admitted-value?) (eq? (.ref profile 'action) 'reject))
        (error "resident import footprint contract rejected test"
               'testing-duplicate-large-import-closure
               test-name
               (length violation-values)
               maximum-shared))
      receipt)))

;; : (forall (t p v) (-> t String (List p) v))
;; : (-> TestingInterface TestName (List Path) Value)
(def (testing-interface-call-with-prepared-source-graph testing test roots)
  (unless (testing-interface-profile-enabled? testing 'source-admission)
    (error "testing source-admission profile is not enabled" test))
  (unless (and (list? roots)
               (pair? roots)
               (andmap (lambda (root)
                         (and (string? root) (> (string-length root) 0)))
                       roots))
    (error "invalid testing prepared source roots" roots))
  (unless (.slot? testing '.admit-prepared-source-graph)
    (error "testing interface has no prepared source graph admission method"
           test))
  (call-with-asp-gerbil-scheme-prepared-source-graph
   (lambda ()
     (when (resident-footprint-profile-for testing test)
       (testing-interface-admit-resident-import-footprints!
        testing test roots))
     (.call testing .admit-prepared-source-graph test roots))))

;; : (forall (t r) (-> t String (List r) TestSuite))
;; : (-> TestingInterface TestName (List Path) TestSuite)
(def (testing-interface-prepared-source-admission-suite testing test roots)
  (let (admit-prepared-source-graph
        (cut testing-interface-call-with-prepared-source-graph
             testing test roots))
    (test-suite "prepared native source graph admission"
      (test-case "admit the graph prepared by the native test harness"
        (admit-prepared-source-graph)))))
