;;; Boundary:
;;; - Source closure order is derived from each package's own gerbil.pkg identity.
;;; - No downstream component manifest or project-specific catalog participates.
(import (only-in :std/test test-suite test-case check)
        (only-in :std/srfi/1 list-index)
        :asp-gerbil-scheme/src/build-api/source-closure)

(export source-closure-test)

;; ensure-directory
;;   : (-> Path Void)
(def (ensure-directory path)
  (unless (file-exists? path)
    (create-directory path)))

;; write-text
;;   : (-> Path String Void)
(def (write-text path text)
  (call-with-output-file path
    (lambda (port) (display text port))))

;;; This suite keeps package-identity resolution and dependency ordering in one
;;; boundary so a downstream package is tested without ASP-owned project data.
;; source-closure-test
;;   : TestSuite
(def source-closure-test
  (test-suite
   "ASP_GERBIL_SCHEME package source closure"

   (test-case "workspace source order emits dependencies before importers"
     (let* ((observability "src/building/observability.ss")
            (facade "src/building/facade.ss")
            (ordered (asp-gerbil-scheme-source-dependency-order
                      (current-directory)
                      (list facade))))
       ;;; Index comparison allows unrelated transitive modules between the
       ;;; dependency and facade while preserving their required order.
       (check (< (list-index (lambda (source)
                              (equal? source observability))
                            ordered)
                 (list-index (lambda (source)
                              (equal? source facade))
                            ordered))
              => #t)))

   (test-case "downstream package identity owns its qualified source closure"
     (let* ((root ".run/source-closure-downstream")
            (source-root (string-append root "/src"))
            (dependency "src/dependency.ss")
            (interface "src/interface.ss"))
       (ensure-directory ".run")
       (ensure-directory root)
       (ensure-directory source-root)
       (write-text (string-append root "/gerbil.pkg")
                   "(package: sample/downstream)\n")
       (write-text (string-append root "/src/dependency.ss")
                   "(export value)\n(def value 42)\n")
       (write-text (string-append root "/src/interface.ss")
                   "(import :std/sugar :sample/downstream/src/dependency)\n(export answer)\n(def answer value)\n")
       (check (asp-gerbil-scheme-source-dependency-order root (list interface))
              => (list dependency interface))))

   ))
