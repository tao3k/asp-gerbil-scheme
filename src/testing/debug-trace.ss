;;; -*- Gerbil -*-
;;; Optional execution adapter for the declarative debug-trace Profile.

(import (only-in :clan/poo/debug trace-poo)
        (only-in :std/srfi/1 find)
        (only-in ./extension
                 testing-interface-profiles-for
                 testing-profile-name))

(export testing-interface-trace-poo-for)

(def (testing-interface-trace-poo-for testing test poo
                                      name: (name 'testing-profile-target))
  (if (find (lambda (profile)
              (eq? (testing-profile-name profile) 'debug-trace))
            (testing-interface-profiles-for testing test))
    (trace-poo poo name)
    poo))
