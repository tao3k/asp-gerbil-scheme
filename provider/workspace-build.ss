#!/usr/bin/env gxi
;;; -*- Gerbil -*-
;;; Build the complete workspace-owned gslph artifact consumed by ASP CAS.

(import (only-in :gerbil/gambit
                 current-directory
                 getenv)
        (only-in :std/misc/path path-expand path-normalize)
        (only-in :std/misc/process run-process/batch)
        (only-in "../src/build-api/native-build"
                 workspace-install-target))
(export main)

(def +workspace-artifact-relative-root+
  "build/workspace-provider")

;; : (-> Path)
(def (workspace-artifact-root)
  (let* ((expected (path-normalize
                    (path-expand +workspace-artifact-relative-root+
                                 (current-directory))))
         (configured (getenv "GSLPH_WORKSPACE_ARTIFACT_ROOT" #f))
         (actual (and configured
                      (path-normalize
                       (path-expand configured (current-directory))))))
    (unless (and actual (string=? actual expected))
      (error "workspace artifact root mismatch"
             actual
             expected))
    actual))

;; : (-> Void)
(def (main . _)
  (let (artifact-root (workspace-artifact-root))
    (run-process/batch ["rm" "-rf" artifact-root])
    (workspace-install-target artifact-root)))
