;;; -*- Gerbil -*-
;;; Current-system profile data for upstream clan/building package builds.

(import :gerbil/gambit
        (only-in :clan/poo/object .def)
        (only-in "../object-family/syntax" defpoo-object-family poo-family-ref)
        (only-in :std/misc/ports read-all-as-string)
        (only-in :std/misc/process run-process)
        (only-in :std/sugar ormap)
        (only-in :std/srfi/13 string-trim-both))

(export asp-gerbil-scheme-native-profile-prototype
        asp-gerbil-scheme-portable-native-profile
        asp-gerbil-scheme-macos-native-profile
        asp-gerbil-scheme-linux-native-profile
        asp-gerbil-scheme-host-native-profile
        asp-gerbil-scheme-default-native-profile
        asp-gerbil-scheme-native-profile-name
        asp-gerbil-scheme-native-profile-platform
        asp-gerbil-scheme-native-profile-architecture
        asp-gerbil-scheme-native-profile-executable-gsc-options
        asp-gerbil-scheme-native-profile-prepare!)

;; : (-> (List String) (Maybe Path))
(def (native-profile-homebrew-prefix packages)
  (ormap
   (lambda (package)
     (try
      (let (prefix
            (string-trim-both
             (run-process ["brew" "--prefix" package]
                          coprocess: read-all-as-string
                          stderr-redirection: #t)))
        (and (> (string-length prefix) 0) prefix))
      (catch _ #f)))
   packages))

(defpoo-object-family
  (prototype asp-gerbil-scheme-native-profile-prototype
             (name 'portable)
             (platform 'portable)
             (architecture (car (system-type)))
             (executable-gsc-options [])
             (prepare! (lambda (_pkg-config-libs) #!void)))
  (accessors poo-family-ref
             (required
              (asp-gerbil-scheme-native-profile-name name)
              (asp-gerbil-scheme-native-profile-platform platform)
              (asp-gerbil-scheme-native-profile-architecture architecture)
              (asp-gerbil-scheme-native-profile-executable-gsc-options
               executable-gsc-options)
              (asp-gerbil-scheme-native-profile-prepare! prepare!))
             (optional)))

(def asp-gerbil-scheme-portable-native-profile
  asp-gerbil-scheme-native-profile-prototype)

(.def (asp-gerbil-scheme-macos-native-profile
       @ asp-gerbil-scheme-native-profile-prototype)
  (name 'macos-native)
  (platform 'macos)
  ;; Keep the public/default compiler contract at gcc. A Homebrew
  ;; Gerbil/Gambit build can retain a versioned gcc-N plus linker flags that no
  ;; longer match the current SDK; the unversioned platform command avoids
  ;; inheriting that installation-time drift. clan/building still owns option
  ;; normalization and applies this only to final executable forms.
  (executable-gsc-options '("-cc" "gcc"))
  (prepare!
   (lambda (pkg-config-libs)
     (when (member "openssl" (or pkg-config-libs []))
       (let (prefix
             (native-profile-homebrew-prefix '("openssl@3" "openssl")))
         (when prefix
           (let ((directory (string-append prefix "/lib/pkgconfig"))
                 (current (getenv "PKG_CONFIG_PATH" #f)))
             (setenv "PKG_CONFIG_PATH"
                     (if (and current (> (string-length current) 0))
                       (string-append directory ":" current)
                       directory)))))))))

(.def (asp-gerbil-scheme-linux-native-profile
       @ asp-gerbil-scheme-native-profile-prototype)
  (name 'linux-native)
  (platform 'linux))

;; Concrete selection is compile-time stable; architecture remains an explicit
;; runtime fact so arm64 and x86_64 hosts retain distinct evidence.
(def asp-gerbil-scheme-host-native-profile
  (cond-expand
   (darwin asp-gerbil-scheme-macos-native-profile)
   (linux asp-gerbil-scheme-linux-native-profile)
   (else asp-gerbil-scheme-portable-native-profile)))

(def asp-gerbil-scheme-default-native-profile
  asp-gerbil-scheme-host-native-profile)
