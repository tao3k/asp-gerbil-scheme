;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import :std/test
        (only-in :std/string/path path-expand)
        (only-in :asp-gerbil-scheme/building-api
                 asp-gerbil-scheme-package-spec!
                 asp-gerbil-scheme-package-native-spec
                 asp-gerbil-scheme-package-policy-native-spec
                 asp-gerbil-scheme-library-package-prototype))

(export build-api-policy-projection-test)

(asp-gerbil-scheme-package-spec!
 (policy-small-fixture @ asp-gerbil-scheme-library-package-prototype)
 (spec policy-small-spec)
 (modules '("small")))

(asp-gerbil-scheme-package-spec!
 (policy-large-fixture @ asp-gerbil-scheme-library-package-prototype)
 (spec policy-large-spec)
 (modules '("large")))

(asp-gerbil-scheme-package-spec!
 (policy-nested-fixture @ asp-gerbil-scheme-library-package-prototype)
 (spec policy-nested-spec)
 (native-spec [[ssi: "interface" [gxc: "large"]]]))

(def policy-extension-count 0)

(asp-gerbil-scheme-package-spec!
 (policy-extended-fixture @ asp-gerbil-scheme-library-package-prototype)
 (spec policy-extended-spec)
 (modules '("small"))
 (spec-projector
  (lambda (package-spec)
    (set! policy-extension-count (+ policy-extension-count 1))
    (asp-gerbil-scheme-package-policy-native-spec package-spec))))

(def +policy-fixture-root+
  (path-expand ".run/build-api-policy-projection" (current-directory)))

(def (write-policy-fixture!)
  (unless (file-exists? ".run") (create-directory ".run"))
  (unless (file-exists? +policy-fixture-root+)
    (create-directory +policy-fixture-root+))
  (call-with-output-file
   (path-expand "gerbil.pkg" +policy-fixture-root+)
   (lambda (port) (display "(package: build-api-policy-projection)\n" port)))
  (call-with-output-file
   (path-expand "small.ss" +policy-fixture-root+)
   (lambda (port)
     (display ";;; -*- Gerbil -*-\n;;; Small fixture.\n(def small 1)\n" port)))
  (call-with-output-file
   (path-expand "large.ss" +policy-fixture-root+)
   (lambda (port)
     (display ";;; -*- Gerbil -*-\n;;; Large fixture.\n(def large 1)\n" port)
     (for-each (lambda (_) (display ";; large source\n" port))
               (iota 1000)))))

(def (with-policy-fixture thunk)
  (write-policy-fixture!)
  (let (previous (current-directory))
    (dynamic-wind
      (lambda () (current-directory +policy-fixture-root+))
      thunk
      (lambda () (current-directory previous)))))

(def build-api-policy-projection-test
  (test-suite "Building API admits its declared source projection"
    (test-case "unselected large source is outside the build graph"
      (check (with-policy-fixture policy-small-spec) => '("small")))
    (test-case "ordinary build projects selected sources without policy scan"
      (check (with-policy-fixture policy-large-spec) => '("large")))
    (test-case "explicit policy checks selected source"
      (let (previous (getenv "ASP_GERBIL_SCHEME_POLICY" #f))
        (dynamic-wind
          (lambda () (setenv "ASP_GERBIL_SCHEME_POLICY" "1"))
          (lambda ()
            (check (with-policy-fixture policy-small-spec) => '("small"))
            (check-exception (with-policy-fixture policy-large-spec) true))
          (lambda ()
            (if previous
              (setenv "ASP_GERBIL_SCHEME_POLICY" previous)
              (setenv "ASP_GERBIL_SCHEME_POLICY"))))))
    (test-case "nested native module targets also receive policy"
      (check (with-policy-fixture
              (lambda ()
                (asp-gerbil-scheme-package-native-spec policy-nested-fixture)))
             => [[ssi: "interface" [gxc: "large"]]])
      (let (previous (getenv "ASP_GERBIL_SCHEME_POLICY" #f))
        (dynamic-wind
          (lambda () (setenv "ASP_GERBIL_SCHEME_POLICY" "1"))
          (lambda ()
            (check-exception (with-policy-fixture policy-nested-spec) true))
          (lambda ()
            (if previous
              (setenv "ASP_GERBIL_SCHEME_POLICY" previous)
              (setenv "ASP_GERBIL_SCHEME_POLICY"))))))
    (test-case "downstream POO slot can compose explicit policy"
      (set! policy-extension-count 0)
      (check (with-policy-fixture policy-extended-spec) => '("small"))
      (check policy-extension-count => 1))))
