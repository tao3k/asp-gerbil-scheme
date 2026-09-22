;;; -*- Gerbil -*-
;;; Optional execution adapter for the declarative debug-trace Profile.

(import (only-in :clan/poo/debug trace-poo)
        (only-in :std/list/list find)
        (only-in ./extension
                 testing-interface-profiles-for
                 testing-profile-name))

(export testing-interface-trace-poo-for)

;; : (forall (t p) (-> t String p p))
;; : (-> TestingInterface Test PooObject PooObject)
(def (testing-interface-trace-poo-for testing test poo
                                      name: (name 'testing-profile-target))
  (if (find (lambda (profile)
              (eq? (testing-profile-name profile) 'debug-trace))
            (testing-interface-profiles-for testing test))
    (trace-poo poo name)
    poo))
