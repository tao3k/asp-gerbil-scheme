(import :std/test
        (only-in :gerbil/gambit create-directory file-exists? setenv)
        (only-in :std/misc/path path-expand)
        "../src/building/native-toolchain")

(def (touch path)
  (call-with-output-file path (lambda (port) (display "compiler" port))))

(def (with-cohort gxc gsc thunk)
  (let ((old-gxc (getenv "GXC" #f))
        (old-gsc (getenv "GSC" #f)))
    (dynamic-wind
      (lambda () (setenv "GXC" gxc) (setenv "GSC" gsc))
      thunk
      (lambda ()
        (setenv "GXC" (or old-gxc ""))
        (setenv "GSC" (or old-gsc ""))))))

(def native-toolchain-cohort-test
  (test-suite "native toolchain cohort"
    (test-case "Homebrew cohort selects system clang and no SDK"
        (with-cohort "/opt/homebrew/bin/gxc" "/opt/homebrew/bin/gsc"
            (lambda ()
              (let (toolchain (native-toolchain-default))
                (check (native-toolchain-toolchain-kind toolchain) => "homebrew-gerbil")
                (check (native-toolchain-compiler-path toolchain) => "/usr/bin/clang")
                (check (native-toolchain-sdkroot toolchain) => "")))))
    (test-case "static Builder publishes the upstream linker variable and restores it"
      (let ((previous (getenv "GERBIL_GCC" #f))
            (observed #f))
        (dynamic-wind
          (lambda () (setenv "GERBIL_GCC" "previous-linker"))
          (lambda ()
            (with-native-toolchain
             (make-native-toolchain "" "" "/usr/bin/clang" "homebrew-gerbil" "darwin-system")
             (lambda () (set! observed (getenv "GERBIL_GCC" #f))))
            (check observed => "/usr/bin/clang")
            (check (getenv "GERBIL_GCC" #f) => "previous-linker"))
          (lambda () (setenv "GERBIL_GCC" (or previous ""))))))
    (test-case "mixed compiler cohort is rejected"
      (with-cohort "/opt/homebrew/bin/gxc" "/nix/store/gsc"
        (lambda ()
          (let (rejected? #f)
            (with-catch
             (lambda (_) (set! rejected? #t))
             (lambda () (native-toolchain-default)))
            (check rejected? => #t)))))
    (test-case "Nix cohort is classified without changing its SDK"
      (check (toolchain-family "/nix/store/gxc/bin/gxc") => 'nix-gerbil)
      (check (toolchain-family "/nix/store/gsc/bin/gsc") => 'nix-gerbil))
    (test-case "unknown compiler cohort is rejected"
      (with-cohort "/usr/bin/gcc" "/usr/bin/gcc"
        (lambda ()
          (let (rejected? #f)
            (with-catch
             (lambda (_) (set! rejected? #t))
             (lambda () (native-toolchain-default)))
            (check rejected? => #t)))))
    ))

(export native-toolchain-cohort-test)
