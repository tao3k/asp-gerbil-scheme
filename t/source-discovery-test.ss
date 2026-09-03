;;; -*- Gerbil -*-

(import :gerbil/gambit
        :std/test
        (only-in :std/misc/path path-directory path-expand)
        (only-in :std/misc/process run-process/batch)
        :asp-gerbil-scheme/src/build-api/source-discovery)

(export source-discovery-test)

(def +source-discovery-test-root+
  (path-expand "asp-gerbil-scheme-source-discovery"
               (or (getenv "TMPDIR" #f) "/tmp")))

(def (ensure-directory* path)
  (unless (file-exists? path)
    (let (parent (path-directory path))
      (when (and parent (not (equal? parent path)))
        (ensure-directory* parent)))
    (create-directory path)))

(def (write-text path text)
  (ensure-directory* (path-directory path))
  (call-with-output-file path
    (cut display text <>)))

(def (fixture-path root path)
  (path-expand path root))

(def (write-module root path text)
  (write-text (fixture-path root path) text))

(def (call-with-path value thunk)
  (let (previous (getenv "PATH" #f))
    (dynamic-wind
      (cut setenv "PATH" value)
      thunk
      (lambda ()
        (when previous
          (setenv "PATH" previous))))))

(def source-discovery-test
  (test-suite "Build API source discovery"
    (test-case "Git filters ignored candidates without owning source discovery"
      (let (root (fixture-path +source-discovery-test-root+ "checkout"))
        (ensure-directory* root)
        (run-process/batch ["git" "init" "--quiet"] directory: root)
        (write-module root ".gitignore" "ignored.ss\ngenerated/\n")
        (write-module root "src/.gitignore" "hidden.ss\n!visible.ss\n")
        (write-module root "src/kept.ss" "(export kept)\n(def kept #t)\n")
        (write-module root "src/unstaged.ss" "(export unstaged)\n")
        (write-module root "src/hidden.ss" "(export hidden)\n")
        (write-module root "src/visible.ss" "(export visible)\n")
        (write-module root "ignored.ss" "(export ignored)\n")
        (write-module root "tracked-ignored.ss" "(export tracked)\n")
        (write-module root "generated/generated.ss" "(export generated)\n")
        (write-module root "main.ss" "(export main)\n")
        (write-module root "tool.ss" "#!/usr/bin/env gxi\n(displayln 'tool)\n")
        (run-process/batch ["chmod" "+x" "tool.ss"] directory: root)
        (run-process/batch
         ["git" "add" ".gitignore" "src/.gitignore" "src/kept.ss"]
         directory: root)
        (run-process/batch ["git" "add" "--force" "tracked-ignored.ss"]
                           directory: root)
        (check (all-gerbil-modules root: root)
               => '("src/kept.ss" "src/unstaged.ss" "src/visible.ss"
                    "tracked-ignored.ss"))))

    (test-case "source archives retain upstream discovery without Git"
      (let (root (fixture-path +source-discovery-test-root+ "archive"))
        (ensure-directory* root)
        (write-module root "src/library.ss" "(export library)\n")
        (write-module root "ignored/private.ss" "(export private)\n")
        (check (call-with-path
                "/nonexistent"
                (lambda ()
                  (all-gerbil-modules
                   root: root
                   exclude-dirs: '("ignored"))))
               => '("src/library.ss"))))))
