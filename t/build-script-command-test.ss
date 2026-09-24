(import :std/test
        (only-in :std/misc/process run-process))
(export build-script-command-test)

(def build-script-command-test
  (test-suite "native package command surface"
    (test-case "library and provider expose the standard clean contract"
      (for-each
       (lambda (script)
         (check (run-process ["gerbil" "interactive" script "meta"] coprocess: read)
                => '("spec" "compile" "clean")))
       '("build.ss" "build-provider.ss")))
    (test-case "Gambit process limits precede the Gerbil subcommand"
      (check
       (run-process
        ["gerbil" "-:max-heap=1024M" "interactive" "-e"
         "(write 'native-runtime-option-ok)"]
        coprocess: read)
       => 'native-runtime-option-ok))))
