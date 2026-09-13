;;; -*- Gerbil -*-
;;; Lightweight source catalog and target normalization for PackageSpec.
;;; std/make and std/build-script remain the only build executors.

(import :gerbil/gambit
        (only-in :std/misc/path
                 path-default-extension path-extension-is?)
        (only-in :std/srfi/1 lset-difference)
        (only-in :clan/filesystem find-files path-is-script?))

(export all-gerbil-modules
        default-exclude-dirs
        remove-build-file
        normalize-spec)

(def +default-exclude-files+ '("main.ss" "manifest.ss"))
(def default-exclude-dirs '("run" "t" ".git" "_darcs" ".gerbil"))

;; : (forall (p) (-> (List p) (List p) (List p)))
;; all-gerbil-modules
;; : (-> (List Path) (List Path) (List Path))
(def (all-gerbil-modules exclude: (exclude +default-exclude-files+)
                         exclude-dirs: (exclude-dirs default-exclude-dirs))
  ((cut lset-difference equal? <> exclude)
   (find-files ""
               (lambda (path)
                 (and (path-extension-is? path ".ss")
                      (not (path-is-script? path))))
               recurse?:
               (lambda (path)
                 (not (member (path-strip-directory path) exclude-dirs))))))

;; : (forall (p) (-> p String (-> p Boolean)))
;; source-file-matcher
;; : (-> Path String (-> Path Boolean))
(def (source-file-matcher file (extension ".ss"))
  (let* ((with-extension (path-default-extension file extension))
         (without-extension (path-strip-extension with-extension)))
    (lambda (candidate)
      (or (equal? with-extension candidate)
          (equal? without-extension candidate)))))

;; : (forall (p s) (-> (List s) p (List s)))
;; remove-build-file
;; : (-> (List BuildSpec) Path (List BuildSpec))
(def (remove-build-file files file)
  (let (file? (source-file-matcher file))
    (filter (match <>
              ((? file?) #f)
              ([gxc: (? file?) . _] #f)
              (_ #t))
            files)))

;; : (forall (s o) (-> s (List o) s))
;; normalize-spec
;; : (-> BuildSpec (List BuildOption) BuildSpec)
(def (normalize-spec spec gsc-options)
  (match spec
    ((? string?) [gxc: spec . gsc-options])
    ([static-include: _] spec)
    ([(? (cut member <> '(gxc: gsc: exe: static-exe:))) . _]
     (append spec gsc-options))))
