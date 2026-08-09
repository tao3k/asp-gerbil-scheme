;;; -*- Gerbil -*-
;;; CLI build specification contracts.

(import :gerbil/gambit
        :std/test
        (only-in :std/srfi/1 filter)
        (only-in :std/sugar ormap)
        "../src/build-api/native-build"
        "../src/build-api/package-spec"
        "../src/build-api/release-modules")
(export cli-build-spec-test)

;; : (-> (List (List Path)) Path (Or False Integer))
(def (module-stage-index stages module-path)
  (let loop ((rest stages) (index 0))
    (cond
     ((null? rest) #f)
     ((member module-path (car rest)) index)
     (else (loop (cdr rest) (+ index 1))))))

;; : (-> (List (List Path)) Path Path Boolean)
(def (module-stage-before? stages dependency dependent)
  (let ((dependency-index (module-stage-index stages dependency))
        (dependent-index (module-stage-index stages dependent)))
    (and dependency-index
         dependent-index
         (< dependency-index dependent-index))))

;; : TestSuite
(def cli-build-spec-test
  (test-suite "gerbil scheme harness CLI build spec"
    (test-case "release build spec uses native exe linker root"
      (let (spec (compile-spec #f #t #f))
        (check (member "cli-release-linker.ss" spec) => #f)
        (check (member "cli-launcher.ss" spec) ? true)
        (check (ormap (lambda (entry)
                        (match entry
                          ([optimized-exe: "cli-release-linker" bin: "gslph" . _] #t)
                          (_ #f)))
                      spec)
               => #t)
        (check (ormap (lambda (entry)
                        (match entry
                          ([optimized-exe: "cli-dev-linker" bin: "gslph" . _] #t)
                          (_ #f)))
                      spec)
               => #f)))
    (test-case "release binary builds runtime module graph"
      (let (spec (cli-binary-build-spec #t))
        (check (member "cli-release-linker.ss" spec) => #f)
        (check (member "cli-launcher.ss" spec) ? true)
        (check (ormap (lambda (entry)
                        (match entry
                          ([optimized-exe: "cli-release-linker" bin: "gslph" . _] #t)
                          (_ #f)))
                      spec)
               => #t)
        (check (member "parser/model.ss" spec) ? true)
        (check (member "policy/repair.ss" spec) ? true)
        (check (member "policy/core.ss" spec) => #f)))
    (test-case "release binary uses the bounded parser-owned projection"
      (let (spec (cli-binary-build-spec #t))
      (check cli-release-module-count => 109)
      (check cli-release-closure-count => 110)
        (check (length (filter string? spec)) => cli-release-module-count)
        (check (member "commands/evidence.ss" spec) ? true)
        (check (member "format/facade.ss" spec) ? true)
        (check (member "build-api/native-build.ss" spec) => #f)
        (check (member "building/facade.ss" spec) => #f)
        (check (member "scenario/benchmark-contract.ss" spec) => #f)
        (check (member "snapshot/facade.ss" spec) => #f)
        (check (member "testing/framework.ss" spec) => #f)))
    (test-case "non-release binary build spec stays bootstrap scoped"
      (let (spec (cli-binary-build-spec #f))
        (check (member "cli-dev-linker.ss" spec) => #f)
        (check (ormap (lambda (entry)
                        (match entry
                          ([optimized-exe: "cli-dev-linker" bin: "gslph" . _] #t)
                          (_ #f)))
                      spec)
               => #t)
        (check (ormap (lambda (entry)
                        (match entry
                          ([optimized-exe: "cli-release-linker" bin: "gslph" . _] #t)
                          (_ #f)))
                      spec)
               => #f)
        (check (member "parser/model.ss" spec) => #f)
        (check (member "policy/core.ss" spec) => #f)))
    (test-case "binary build spec includes fmt command"
      (let (spec (cli-binary-build-spec #f))
        (check (member "commands/fmt.ss" spec) ? true)))
    (test-case "default compile spec builds full harness and benchmark gate helper"
      (let (spec (compile-spec #f #f #f))
        (check (member "benchmark/gate.ss" spec) ? true)
        (check (member "parser/model.ss" spec) ? true)
        (check (member "policy/core.ss" spec) ? true)))
    (test-case "full install precompile spec closes the formatter runtime graph"
      (let (spec (compile-spec #t #t #f))
        (check (member "parser/reader.ss" spec) ? true)
        (check (member "format/facade.ss" spec) ? true)
        (check (member "commands/fmt.ss" spec) ? true)))
    (test-case "policy stages preserve generated SSI dependency order"
      (let (stages (gslph-package-api-stage-specs))
        (check (module-stage-before? stages
                                     "policy/model.ss"
                                     "policy/agent-poo-loop-performance.ss")
               => #t)
        (check (module-stage-before? stages
                                     "policy/agent-poo-object-literal.ss"
                                     "policy/agent-poo-loop-performance.ss")
               => #t)
        (check (module-stage-before? stages
                                     "policy/agent-poo-loop-performance.ss"
                                     "policy/agent-poo.ss")
               => #t)
        (check (module-stage-before? stages
                                     "policy/agent-poo.ss"
                                     "policy/agent-basic.ss")
               => #t)
        (check (module-stage-before? stages
                                     "policy/agent-basic.ss"
                                     "policy/agent.ss")
               => #t)
        (check (module-stage-before? stages
                                     "policy/agent.ss"
                                     "policy/core.ss")
               => #t)
        (check (module-stage-before? stages
                                     "policy/core.ss"
                                     "policy/facade.ss")
               => #t)
        (check (module-stage-before? stages
                                     "policy/facade.ss"
                                     "policy/gxtest-report.ss")
               => #t)))
    (test-case "project CLI stages follow Build and Testing interfaces"
      (let (stages (gslph-package-api-stage-specs))
        (check (module-stage-before? stages
                                     "build-api/native-build.ss"
                                     "build-api/project-build.ss")
               => #t)
        (check (module-stage-before? stages
                                     "testing/project-build.ss"
                                     "build-api/project-build.ss")
               => #t)))
    (test-case "policy stages preserve style and repair dependency order"
      (let (stages (gslph-package-api-stage-specs))
        (check (module-stage-before? stages
                                     "policy/agent-style-gerbil-signal-support.ss"
                                     "policy/agent-style-gerbil-signals.ss")
               => #t)
        (check (module-stage-before? stages
                                     "policy/agent-style-gerbil-signals.ss"
                                     "policy/agent-style-details.ss")
               => #t)
        (check (module-stage-before? stages
                                     "policy/gerbil-utils-source.ss"
                                     "policy/agent-style-shape.ss")
               => #t)
        (check (module-stage-before? stages
                                     "policy/agent-style-details.ss"
                                     "policy/agent-style.ss")
               => #t)
        (check (module-stage-before? stages
                                     "policy/agent-style.ss"
                                     "policy/agent.ss")
               => #t)
        (check (module-stage-before? stages
                                     "policy/catalog.ss"
                                     "policy/repair.ss")
               => #t)
        (check (module-stage-before? stages
                                     "policy/repair.ss"
                                     "policy/facade.ss")
               => #t)))))
