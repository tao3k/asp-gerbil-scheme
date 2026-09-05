;;; Boundary: native compiler environment policy belongs to Building, never to callers.
(import (only-in :std/misc/path path-directory path-expand)
        (only-in :std/source gerbil-home)
        (only-in :std/srfi/13 string-split string-prefix?)
        :gerbil/gambit)

(export native-toolchain
        native-toolchain?
        make-native-toolchain
        native-toolchain-sdkroot
        native-toolchain-developer-dir
        native-toolchain-compiler-path
        native-toolchain-toolchain-kind
        native-toolchain-sdk-kind
        resolve-executable
        resolve-cohort-executable
        toolchain-family
        native-toolchain-default
        with-native-toolchain)

;; : (-> String String Path String String NativeToolchain)
(defstruct native-toolchain (sdkroot developer-dir compiler-path toolchain-kind sdk-kind))

;; : (-> String String Path)
(def (resolve-executable name env-name)
  (let* ((explicit (getenv env-name #f))
         (path (or (getenv "PATH" #f) ""))
         (candidates (if (and explicit (not (string=? explicit "")))
                       [explicit]
                       (map (lambda (directory)
                              (path-expand (string-append directory "/" name)))
                            (string-split path #\:)))))
    (let (resolved (find (lambda (candidate) (file-exists? candidate)) candidates))
      (or resolved
          (error "native compiler executable not found on PATH" name env-name)))))

;; Resolve a companion compiler from the selected cohort, never from an
;; unrelated PATH entry. An explicit override remains admissible and is checked
;; by native-toolchain-default against the leader's family.
;; : (-> Path String String Path)
(def (resolve-cohort-executable leader name env-name)
  (let (explicit (getenv env-name #f))
    (if (and explicit (not (string=? explicit "")))
      explicit
      (let ((runtime-companion
             (path-expand (string-append "bin/" name) (gerbil-home)))
            (sibling
             (path-expand (string-append (path-directory leader) "/" name))))
        ;; Homebrew links gxc/gxi but leaves gsc in Gerbil's versioned runtime
        ;; directory because /opt/homebrew/bin/gsc belongs to Ghostscript.
        ;; The active Gerbil runtime is therefore the authoritative cohort.
        (cond
         ((file-exists? runtime-companion) runtime-companion)
         ((file-exists? sibling) sibling)
         (else
          (error "native compiler cohort companion not found"
                 leader name env-name runtime-companion sibling)))))))

;; : (-> Path Symbol)
(def (toolchain-family executable)
  (cond
   ((string-prefix? "/opt/homebrew/" executable) 'homebrew-gerbil)
   ((string-prefix? "/nix/store/" executable) 'nix-gerbil)
   (else 'unknown)))

;; : (-> NativeToolchain)
(def (native-toolchain-default)
  (let* ((gxc (resolve-executable "gxc" "GXC"))
         (gsc (resolve-cohort-executable gxc "gsc" "GSC"))
         (gxc-family (toolchain-family gxc))
         (gsc-family (toolchain-family gsc)))
    (unless (eq? gxc-family gsc-family)
      (error "native Gerbil compiler cohort mismatch" gxc gsc gxc-family gsc-family))
    (unless (or (eq? gxc-family 'homebrew-gerbil)
                (eq? gxc-family 'nix-gerbil))
      (error "native Gerbil compiler cohort is unknown" gxc gsc))
    (if (eq? gxc-family 'homebrew-gerbil)
      (make-native-toolchain "" "" "/usr/bin/clang" "homebrew-gerbil" "darwin-system")
      (if (eq? gxc-family 'nix-gerbil)
        (make-native-toolchain (or (getenv "SDKROOT" #f) "")
                               (or (getenv "DEVELOPER_DIR" #f) "")
                               (or (getenv "CC" #f) "clang")
                               "nix-gerbil"
                               "nix-sdk")
        (make-native-toolchain "" "" (or (getenv "CC" #f) "clang")
                               "unknown" "unknown")))))

;; : (-> String String String)
(def (native-toolchain-value name value)
  (if (string? value)
    value
    (error "native toolchain values must be strings" name value)))

;; : (forall (A) (-> NativeToolchain (-> A) A))
;; : (-> NativeToolchain Thunk Result)
(def (with-native-toolchain toolchain thunk)
  (unless (native-toolchain? toolchain)
    (error "expected native toolchain" toolchain))
  (let ((previous-sdkroot (getenv "SDKROOT" #f))
        (previous-developer-dir (getenv "DEVELOPER_DIR" #f))
        (previous-gerbil-gcc (getenv "GERBIL_GCC" #f))
        (sdkroot (native-toolchain-value
                  "SDKROOT"
                  (native-toolchain-sdkroot toolchain)))
        (developer-dir (native-toolchain-value
                        "DEVELOPER_DIR"
                        (native-toolchain-developer-dir toolchain))))
    (dynamic-wind
      (lambda ()
        (setenv "SDKROOT" sdkroot)
        (setenv "DEVELOPER_DIR" developer-dir)
        ;; Gerbil's static executable driver resolves its final linker through
        ;; GERBIL_GCC, not CC. Keep the setting scoped to this Builder run.
        (setenv "GERBIL_GCC" (native-toolchain-compiler-path toolchain)))
      thunk
      (lambda ()
        (setenv "SDKROOT" (or previous-sdkroot ""))
        (setenv "DEVELOPER_DIR" (or previous-developer-dir ""))
        (setenv "GERBIL_GCC" (or previous-gerbil-gcc ""))))))
