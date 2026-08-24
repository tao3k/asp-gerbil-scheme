;;; -*- Gerbil -*-
;;; Cleanup helpers for generated launcher artifacts.

(import :gerbil/gambit
        (only-in :std/misc/path path-directory path-expand path-strip-directory)
        (only-in "./launcher-receipt" gslph-build-module-artifact-files))
(export cleanup-compile-exe-artifacts!
        cleanup-generated-artifacts!
        cleanup-launcher-binary-artifacts!
        cleanup-launcher-module-artifacts!)

;; : (-> Path Void)
;; Delete a generated artifact when it is present.
(def (delete-file-if-present! path)
  (with-catch
   (lambda (_) #!void)
   (lambda ()
     (when (file-exists? path)
       (delete-file path)))))

;; : (-> (List Path) Void)
;; Delete generated outputs before their source closure is rebuilt.
(def (cleanup-generated-artifacts! paths)
  (for-each delete-file-if-present! paths))

;; : (-> Path Void)
;; Delete native compiler intermediates before rebuilding one launcher binary.
(def (cleanup-compile-exe-artifacts! binpath)
  (let* ((bindir (path-directory binpath))
         (name (path-strip-directory binpath))
         (prefix (string-append name "__exe")))
    (for-each
     (lambda (suffix)
       (delete-file-if-present!
        (path-expand (string-append prefix suffix) bindir)))
     '(".c" "_.c" ".scm" ".o" "_.o"))))

;; : (-> Path Void)
;; Delete a launcher binary and all compiler intermediates associated with it.
(def (cleanup-launcher-binary-artifacts! binpath)
  (delete-file-if-present! binpath)
  (cleanup-compile-exe-artifacts! binpath))

;; : (-> Path (List ModulePath) Void)
;; Remove stale module interfaces so relinking compiles the complete closure.
(def (cleanup-launcher-module-artifacts! output-root module-spec)
  (cleanup-generated-artifacts!
   (apply append
          (map (lambda (module)
                 (gslph-build-module-artifact-files output-root module))
               module-spec))))
