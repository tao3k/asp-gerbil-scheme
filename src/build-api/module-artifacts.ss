;;; -*- Gerbil -*-
;;; Pure paths for Gerbil module build artifacts.

(import (only-in :std/misc/path path-expand)
        (only-in :std/srfi/1 find)
        (only-in :std/srfi/13 string-suffix?)
        :gerbil/gambit)

(export asp-gerbil-scheme-build-module-source-file
        asp-gerbil-scheme-build-module-output-file
        asp-gerbil-scheme-build-module-runtime-artifact-files
        asp-gerbil-scheme-build-module-optimizer-artifact-file
        asp-gerbil-scheme-build-module-optimizer-artifact-current?
        asp-gerbil-scheme-build-module-artifact-files
        asp-gerbil-scheme-build-module-artifact-file)

(def (asp-gerbil-scheme-build-module-source-file source-root module)
  (path-expand module source-root))

(def (asp-gerbil-scheme-module-path-stem module)
  (if (string-suffix? ".ss" module)
    (substring module 0 (- (string-length module) 3))
    module))

(def (asp-gerbil-scheme-build-module-output-file output-root module)
  (path-expand
   (string-append (asp-gerbil-scheme-module-path-stem module) ".scm")
   output-root))

(def (asp-gerbil-scheme-build-module-runtime-artifact-files output-root module)
  (let (scm-file (asp-gerbil-scheme-build-module-output-file output-root module))
    (let (stem (substring scm-file 0 (- (string-length scm-file) 4)))
      [(string-append stem ".ssi")
       (string-append stem "~0.scm")
       scm-file])))

;; SSXI is profile-specific optimizer metadata, not a runnable module output.
;; A non-optimized rebuild must still own and remove it or later consumers can
;; inline specialized bindings that the newly generated runtime does not define.
(def (asp-gerbil-scheme-build-module-optimizer-artifact-file output-root module)
  (let (scm-file (asp-gerbil-scheme-build-module-output-file output-root module))
    (string-append
     (substring scm-file 0 (- (string-length scm-file) 4))
     ".ssxi.ss")))

(def (asp-gerbil-scheme-build-artifact-file-seconds path)
  (time->seconds (file-info-last-modification-time (file-info path))))

;; Optimizer metadata is coherent only when it was generated no earlier than
;; every runnable artifact that exists for the same module. This distinguishes
;; a current SSXI emitted by the active build from metadata left behind when a
;; later non-optimized rebuild refreshed only the runnable outputs.
(def (asp-gerbil-scheme-build-module-optimizer-artifact-current?
      output-root module)
  (let ((optimizer
         (asp-gerbil-scheme-build-module-optimizer-artifact-file
          output-root
          module))
        (runtime-artifacts
         (filter file-exists?
                 (asp-gerbil-scheme-build-module-runtime-artifact-files
                  output-root
                  module))))
    (and (file-exists? optimizer)
         (pair? runtime-artifacts)
         (let (optimizer-seconds
               (asp-gerbil-scheme-build-artifact-file-seconds optimizer))
           (andmap
            (lambda (runtime-artifact)
              (>= optimizer-seconds
                  (asp-gerbil-scheme-build-artifact-file-seconds
                   runtime-artifact)))
            runtime-artifacts)))))

(def (asp-gerbil-scheme-build-module-artifact-files output-root module)
  (append
   (asp-gerbil-scheme-build-module-runtime-artifact-files output-root module)
   [(asp-gerbil-scheme-build-module-optimizer-artifact-file
     output-root
     module)]))

(def (asp-gerbil-scheme-build-module-artifact-file output-root module)
  (let (candidates
        (asp-gerbil-scheme-build-module-runtime-artifact-files
         output-root
         module))
    (or (find file-exists? candidates)
        (asp-gerbil-scheme-build-module-output-file output-root module))))
