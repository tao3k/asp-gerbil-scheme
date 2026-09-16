;;; -*- Gerbil -*-
;;; Prepared-source admission trampoline for the source-admission Profile.

(import (only-in :clan/poo/object .call .slot?)
        (only-in :std/test test-suite test-case)
        (only-in ./extension
                 testing-interface-profile-enabled?)
        (only-in ../build-api/native-import-closure
                 call-with-asp-gerbil-scheme-prepared-source-graph))

(export testing-interface-call-with-prepared-source-graph
        testing-interface-prepared-source-admission-suite)

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
     (.call testing .admit-prepared-source-graph test roots))))

(def (testing-interface-prepared-source-admission-suite testing test roots)
  (test-suite "prepared native source graph admission"
    (test-case "admit the graph prepared by the native test harness"
      (testing-interface-call-with-prepared-source-graph testing test roots))))
