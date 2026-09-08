;;; -*- Gerbil -*-
;;; Declarative host build-environment profiles projected by Package Spec.

(import (only-in :clan/poo/object .def .get)
        :gerbil/gambit)

(export asp-gerbil-scheme-build-environment-profile-prototype
        asp-gerbil-scheme-portable-build-environment-profile
        asp-gerbil-scheme-macos-build-environment-profile
        asp-gerbil-scheme-host-build-environment-profile
        asp-gerbil-scheme-build-environment-profile-name
        asp-gerbil-scheme-build-environment-profile-bindings
        asp-gerbil-scheme-apply-build-environment-profile!)

(.def asp-gerbil-scheme-build-environment-profile-prototype
  (name 'portable)
  (bindings []))

(.def (asp-gerbil-scheme-portable-build-environment-profile
       @ asp-gerbil-scheme-build-environment-profile-prototype))

;; A Homebrew Gerbil runtime must not inherit Nix/Xcode SDK selectors from the
;; repository shell.  #f is the declarative value for an absent binding.
(.def (asp-gerbil-scheme-macos-build-environment-profile
       @ asp-gerbil-scheme-build-environment-profile-prototype)
  (name 'macos-native)
  (bindings '(("SDKROOT" . #f)
              ("DEVELOPER_DIR" . #f))))

(def asp-gerbil-scheme-host-build-environment-profile
  (cond-expand
   (darwin asp-gerbil-scheme-macos-build-environment-profile)
   (else asp-gerbil-scheme-portable-build-environment-profile)))

(def (asp-gerbil-scheme-build-environment-profile-name profile)
  (.get profile name))

(def (asp-gerbil-scheme-build-environment-profile-bindings profile)
  (.get profile bindings))

;; The macro-generated spec procedure runs immediately before the upstream
;; std/make call.  Project the declared host environment into that process;
;; callers and workflow files do not reproduce host-specific mutations.
(def (asp-gerbil-scheme-apply-build-environment-profile! profile)
  (for-each
   (lambda (binding)
     (let ((name (car binding))
           (value (cdr binding)))
       (if value
         (setenv name value)
         (setenv name))))
   (asp-gerbil-scheme-build-environment-profile-bindings profile)))
