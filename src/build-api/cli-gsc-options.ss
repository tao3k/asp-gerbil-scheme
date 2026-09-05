;;; -*- Gerbil -*-
;;; GSC option discovery for native asp-gerbil-scheme launcher builds.

(import (only-in :std/misc/path path-directory path-expand)
        (only-in :std/misc/process run-process)
        (only-in :std/srfi/13 string-tokenize)
        :gerbil/gambit
        (only-in "../building/native-toolchain"
                 native-toolchain-default
                 native-toolchain-compiler-path
                 native-toolchain-toolchain-kind
                 native-toolchain-sdk-kind))
(export asp-gerbil-scheme-cli-gsc-options
        asp-gerbil-scheme-cli-gsc-options-cache-key)

;; : (-> (List (Maybe String)))
(def (asp-gerbil-scheme-cli-gsc-options-cache-key)
  (let (toolchain (native-toolchain-default))
    [(native-toolchain-compiler-path toolchain)
     (native-toolchain-toolchain-kind toolchain)
     (native-toolchain-sdk-kind toolchain)
   (getenv "OPENSSL_DIR" #f)
   (getenv "OPENSSL_ROOT_DIR" #f)
   (getenv "PKG_CONFIG" #f)
   (getenv "PKG_CONFIG_PATH" #f)
   (getenv "PKG_CONFIG_LIBDIR" #f)
   (homebrew-openssl-prefix)]))

;; : (-> String)
(def (pkg-config-command)
  (let (command (getenv "PKG_CONFIG" #f))
    (if (and command (not (string=? command "")))
      command
      "pkg-config")))

;; : (-> (Maybe String))
(def (homebrew-openssl-prefix)
  (cond-expand
   (darwin
    (let (status 0)
      (with-catch
       (lambda (_) #f)
       (lambda ()
         (let* ((output
                 (run-process ["brew" "--prefix" "openssl@3"]
                              stderr-redirection: #t
                              check-status:
                              (lambda (exit-status _settings)
                                (set! status exit-status))))
                (tokens (string-tokenize output)))
           (and (zero? status)
                (pair? tokens)
                (car tokens)))))))
   (else #f)))

;; : (-> (Maybe String))
(def (openssl-prefix)
  (or (getenv "OPENSSL_DIR" #f)
      (getenv "OPENSSL_ROOT_DIR" #f)
      (homebrew-openssl-prefix)))

;; : (-> (List String))
(def (cc-compiler-option)
  (let (cc (native-toolchain-compiler-path (native-toolchain-default)))
    (if (and cc (not (string=? cc "")))
      ["-cc" cc]
      [])))

;; : (-> Path Void)
(def (ensure-directory! path)
  (unless (file-exists? path)
    (let (parent (path-directory path))
      (when (and parent
                 (not (string=? parent ""))
                 (not (string=? parent path)))
        (ensure-directory! parent))
      (create-directory path))))

;; : (-> (List String) (List String))
(def (pkg-config-openssl-options args)
  (let (status 0)
    (with-catch
     (lambda (_) [])
     (lambda ()
       (let (output
             (run-process (append [(pkg-config-command)] args ["openssl"])
                          stderr-redirection: #t
                          check-status:
                          (lambda (exit-status _settings)
                            (set! status exit-status))))
         (if (zero? status)
           (string-tokenize output)
           []))))))

;; : (-> (List String))
(def (openssl-prefix-cc-options)
  (let (prefix (openssl-prefix))
    (if prefix
      [(string-append "-I" prefix "/include")]
      [])))

;; : (-> (List String))
(def (openssl-prefix-ld-options)
  (let (prefix (openssl-prefix))
    (if prefix
      [(string-append "-L" prefix "/lib")]
      [])))

;; : (-> (List String))
(def (openssl-cc-options)
  (let (options (pkg-config-openssl-options ["--cflags"]))
    (if (null? options)
      (openssl-prefix-cc-options)
      options)))

;; : (-> (List String))
(def (openssl-ld-options)
  (let (options (pkg-config-openssl-options ["--libs"]))
    (if (null? options)
      (append (openssl-prefix-ld-options)
              '("-lssl" "-lcrypto"))
      options)))

;; : (-> (List String) String)
(def (join-gsc-options options)
  (match options
    ([] "")
    ([option] option)
    ([option . rest]
     (string-append option " " (join-gsc-options rest)))))

;; : (-> String (List String) (List String))
(def (gsc-option flag options)
  (if (null? options)
    []
    [flag (join-gsc-options options)]))

;; : (-> Path Path)
(def (cli-gsc-options-cache-path package-root)
  (path-expand "cli-gsc-options-cache.ss"
               (path-expand ".gerbil/build" package-root)))

;; : (-> Path (List (Maybe String)) (Maybe (List String)))
(def (read-cli-gsc-options-cache package-root key)
  (with-catch
   (lambda (_) #f)
   (lambda ()
     (let (path (cli-gsc-options-cache-path package-root))
       (and (file-exists? path)
            (let (entry (call-with-input-file path read))
              (match entry
                ([version entry-key options]
                 (and (eq? version 'cli-gsc-options-cache-v1)
                      (equal? entry-key key)
                      options))
                (_ #f))))))))

;; : (-> Path (List (Maybe String)) (List String) Void)
(def (write-cli-gsc-options-cache! package-root key options)
  (let (path (cli-gsc-options-cache-path package-root))
    (ensure-directory! (path-directory path))
    (call-with-output-file path
      (lambda (port)
        (write ['cli-gsc-options-cache-v1 key options] port)
        (newline port)))))

;; : (-> (List String))
(def (uncached-cli-gsc-options)
  (append (cc-compiler-option)
          (gsc-option "-cc-options" (openssl-cc-options))
          (gsc-option "-ld-options" (openssl-ld-options))))

;; : (-> Path (List String))
(def (asp-gerbil-scheme-cli-gsc-options package-root)
  (let (key (asp-gerbil-scheme-cli-gsc-options-cache-key))
    (or (read-cli-gsc-options-cache package-root key)
        (let (options (uncached-cli-gsc-options))
          (write-cli-gsc-options-cache! package-root key options)
          options))))
