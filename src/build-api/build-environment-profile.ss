;;; -*- Gerbil -*-
;;; Declarative host build-environment profiles projected by Package Spec.

(import (only-in :clan/poo/object .def .get)
        (only-in "../object-family/syntax" defpoo-object-family poo-family-ref)
        :gerbil/gambit)

(export asp-gerbil-scheme-build-environment-profile-prototype
        asp-gerbil-scheme-portable-build-environment-profile
        asp-gerbil-scheme-macos-build-environment-profile
        asp-gerbil-scheme-host-build-environment-profile
        asp-gerbil-scheme-build-environment-profile-name
        asp-gerbil-scheme-build-environment-profile-bindings
        asp-gerbil-scheme-apply-build-environment-profile!)

(defpoo-object-family
  (prototype asp-gerbil-scheme-build-environment-profile-prototype
             (name 'portable)
             (bindings []))
  (accessors poo-family-ref
             (required
              (asp-gerbil-scheme-build-environment-profile-name name)
              (asp-gerbil-scheme-build-environment-profile-bindings bindings))
             (optional)))

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
