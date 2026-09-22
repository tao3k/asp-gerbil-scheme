;;; -*- Gerbil -*-
;;; Current-system profile data for native std/make package builds.

(import :gerbil/runtime/gambit
        (only-in :clan/poo/object .def)
        (only-in "../object-family/syntax" defpoo-object-family poo-family-ref)
        (only-in :std/misc/ports read-all-as-string)
        (only-in :std/misc/process run-process)

        (only-in :std/string/misc string-trim))

(export asp-gerbil-scheme-native-profile-prototype
        asp-gerbil-scheme-portable-native-profile
        asp-gerbil-scheme-macos-native-profile
        asp-gerbil-scheme-linux-native-profile
        asp-gerbil-scheme-host-native-profile
        asp-gerbil-scheme-default-native-profile
        asp-gerbil-scheme-native-profile-name
        asp-gerbil-scheme-native-profile-platform
        asp-gerbil-scheme-native-profile-architecture
        asp-gerbil-scheme-native-profile-projection-observability-enabled?
        asp-gerbil-scheme-native-profile-projection-observer
        asp-gerbil-scheme-native-profile-projection-heartbeat-seconds
        asp-gerbil-scheme-native-profile-executable-gsc-options
        asp-gerbil-scheme-native-pkg-config-options
        asp-gerbil-scheme-native-profile-prepare!)

;; native-pkg-config-query
;;   : (-> String (List String) String)
;;   | requires libraries names explicitly declared by the PackageSpec
;;   | rationale std/make remains the executor; this process boundary only
;;       projects platform pkg-config output after the host profile has
;;       prepared its search path
(def (native-pkg-config-query option libraries)
  (try
   ;; A successful query may legitimately be empty when headers live in the
   ;; compiler's default include path (notably OpenSSL on Ubuntu).  Process
   ;; status, rather than output length, is the native availability contract.
   (string-trim
    (run-process
     (append ["pkg-config" option] libraries)
     coprocess: read-all-as-string))
   (catch (exception)
     (error "Failed to resolve native library options with pkg-config"
            libraries exception))))

;; asp-gerbil-scheme-native-pkg-config-options
;;   : (-> (List String) (List String))
;;   | doc m%
;;       Projects explicitly declared C libraries into native compiler and
;;       linker option forms consumed by a std/make BuildSpec.
;;
;;       # Examples
;;       ```scheme
;;       (asp-gerbil-scheme-native-pkg-config-options '("openssl"))
;;       ;; => ("-ld-options" "..." "-cc-options" "...")
;;       ```
;;     %
(def (asp-gerbil-scheme-native-pkg-config-options libraries)
  ["-ld-options" (native-pkg-config-query "--libs" libraries)
   "-cc-options" (native-pkg-config-query "--cflags" libraries)])

;; : (-> (List String) (Maybe Path))
(def (native-profile-homebrew-prefix packages)
  (ormap
   (lambda (package)
     (try
      (let (prefix
            (string-trim
             (run-process ["brew" "--prefix" package]
                          coprocess: read-all-as-string
                          stderr-redirection: #t)))
        (and (> (string-length prefix) 0) prefix))
      (catch _ #f)))
   packages))

;; native-profile-default-projection-observability-enabled?
;;   : (-> Boolean)
;;   | rationale normalize the optional process setting once at the POO slot
;;       boundary so projection code receives an ordinary predicate result
(def (native-profile-default-projection-observability-enabled?)
  (cond
   ((getenv "GERBIL_BUILD_VERBOSE" #f)
    => (lambda (value)
         (let (level (string->number value))
           (and (real? level) (> level 0)))))
   (else #f)))

;; Observer : (-> Symbol Integer (List String) Void)
(def (native-profile-default-projection-observer phase elapsed-milliseconds
                                                 fields)
  (let* ((port (current-output-port))
         (record
          (call-with-output-string
           (lambda (buffer)
             (display "[asp-build] phase=" buffer)
             (display phase buffer)
             (for-each
              (lambda (field) (display " " buffer) (display field buffer))
              fields)
             (display " elapsedMs=" buffer)
             (display elapsed-milliseconds buffer)
             (newline buffer)))))
    (write-substring record 0 (string-length record) port)
    (force-output port)))

(defpoo-object-family
  (prototype asp-gerbil-scheme-native-profile-prototype
             (name 'portable)
             (platform 'portable)
             (architecture (car (system-type)))
             (projection-observability-enabled?
              native-profile-default-projection-observability-enabled?)
             (projection-observer
              native-profile-default-projection-observer)
             (projection-heartbeat-seconds 5)
             (executable-gsc-options [])
             (prepare! (lambda (_pkg-config-libs) #!void)))
  (accessors poo-family-ref
             (required
              (asp-gerbil-scheme-native-profile-name name)
              (asp-gerbil-scheme-native-profile-platform platform)
              (asp-gerbil-scheme-native-profile-architecture architecture)
              (asp-gerbil-scheme-native-profile-projection-observability-enabled?
               projection-observability-enabled?)
              (asp-gerbil-scheme-native-profile-projection-observer
               projection-observer)
              (asp-gerbil-scheme-native-profile-projection-heartbeat-seconds
               projection-heartbeat-seconds)
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
  ;; inheriting that installation-time drift. PackageSpec owns option
  ;; projection and applies this only to final executable forms.
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
