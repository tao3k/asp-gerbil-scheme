;;; -*- Gerbil -*-
;;; Same-source native/PackageSpec A/B owned by the Scheme Scenario layer.

(import :gerbil/gambit
        (only-in :clan/timestamp call-with-timing)
        (only-in :std/misc/ports read-all-as-string)
        (only-in :std/misc/process run-process)
        (only-in :std/os/temporaries make-temporary-file-name)
        (only-in :std/srfi/1 count)
        (only-in :std/srfi/13 string-prefix? string-split)
        :asp-gerbil-scheme/src/benchmark/statistics)

(def +scenario-root+ "t/scenarios/building/package-spec-native-ab")
(def +sample-count+ 3)
(def +max-overhead-ns+ 3000000000)
(def +expected-spec+ '("probe.ss"))

(def (scenario-command image build action verbose?)
  (append
   ["env"
    (string-append "GERBIL_PATH=" image)
    (string-append "GERBIL_LOADPATH="
                   (path-expand ".gerbil/lib" (current-directory)) ":"
                   (path-expand ".gerbil/lib" (getenv "HOME")))
    (string-append "GERBIL_BUILD_CORES="
                   (getenv "GERBIL_BUILD_CORES" "4"))]
   ;; Keep performance sampling at std/make's ordinary message level.  Level 9
   ;; intentionally emits the compiler driver's large diagnostic stream and is
   ;; covered independently by build-api-startup-scenario-test.ss.
   (if verbose? ["GERBIL_BUILD_VERBOSE=1"] [])
   ["timeout" "--signal=TERM" "--kill-after=3s" "30s"
    "gerbil" "interactive" build action]))

(def (compile-line-count output)
  (count (lambda (line) (string-prefix? "... compile " line))
         (string-split output #\newline)))

(def (run-spec lane image build)
  (displayln "[package-spec-native-ab] lane=" lane
             " phase=spec event=process-start")
  (force-output)
  (let-values (((elapsed-ns spec)
                (call-with-timing
                 (lambda ()
                   (run-process (scenario-command image build "spec" #f)
                                directory: +scenario-root+
                                coprocess: read)))))
    (displayln "[package-spec-native-ab] lane=" lane
               " phase=spec event=process-returned elapsed-ns=" elapsed-ns
               " target-count=" (length spec))
    (force-output)
    spec))

(def (measure-build lane phase image build)
  (displayln "[package-spec-native-ab] lane=" lane
             " phase=" phase " event=process-start")
  (force-output)
  (let-values (((elapsed-ns output)
                (call-with-timing
                 (lambda ()
                   (run-process
                    (scenario-command image build "compile" #t)
                    directory: +scenario-root+
                    stderr-redirection: #t
                    coprocess: read-all-as-string)))))
    (display output)
    (let (sample
          `((lane . ,lane)
            (phase . ,phase)
            (elapsedNs . ,elapsed-ns)
            (compileCount . ,(compile-line-count output))))
      (displayln "[package-spec-native-ab] lane=" lane
                 " phase=" phase
                 " event=process-returned elapsed-ns=" elapsed-ns
                 " compile-count=" (cdr (assq 'compileCount sample)))
      (force-output)
      sample)))

(def (sample-ref sample key)
  (cdr (assq key sample)))

(def (series-elapsed samples)
  (map (lambda (sample) (sample-ref sample 'elapsedNs)) samples))

(def (series-compile-count samples)
  (apply + (map (lambda (sample) (sample-ref sample 'compileCount)) samples)))

(def (write-receipt path receipt)
  (call-with-output-file path
    (lambda (port) (pretty-print receipt port))))

(def (main . _)
  (displayln "[package-spec-native-ab] phase=scenario-start event=ready")
  (force-output)
  (let* ((run-root (make-temporary-file-name "asp-package-spec-native-ab"))
         (native-image (path-expand "native" run-root))
         (asp-image (path-expand "asp" run-root))
         (receipt-path (path-expand "receipt.ss" run-root)))
    (create-directory* native-image)
    (create-directory* asp-image)
    (let ((native-spec (run-spec 'native native-image "native-build.ss"))
          (asp-spec (run-spec 'asp asp-image "asp-build.ss")))
      (unless (and (equal? native-spec asp-spec)
                   (equal? native-spec +expected-spec+))
        (error "A/B lanes projected different BuildSpec values"
               native-spec asp-spec))
      (displayln "[package-spec-native-ab] phase=spec-equal spec=" native-spec))
    (let* ((native-cold
            (measure-build 'native 'cold native-image "native-build.ss"))
           (asp-cold
            (measure-build 'asp 'cold asp-image "asp-build.ss"))
           (warm-pairs
            (map
             (lambda (sample-index)
               (let (phase
                     (string->symbol
                      (string-append "warm" (number->string sample-index))))
                 (list
                  (measure-build 'native phase native-image "native-build.ss")
                  (measure-build 'asp phase asp-image "asp-build.ss"))))
             (iota +sample-count+ 1)))
           (native-warm (map car warm-pairs))
           (asp-warm (map cadr warm-pairs))
           (native-warm-ns (series-elapsed native-warm))
           (asp-warm-ns (series-elapsed asp-warm))
           (native-p50 (benchmark-sample-percentile native-warm-ns 50))
           (asp-p50 (benchmark-sample-percentile asp-warm-ns 50))
           (overhead-ns (- asp-p50 native-p50))
           (native-warm-compile (series-compile-count native-warm))
           (asp-warm-compile (series-compile-count asp-warm))
           (receipt
            `((schema . asp-gerbil-scheme.package-spec-native-ab.v1)
              (executor . std/make)
              (targetCount . 1)
              (sourceTarget . "probe.ss")
              (projectedBuildSpec "probe.ss")
              (nativeCold . ,native-cold)
              (aspCold . ,asp-cold)
              (nativeWarm . ,native-warm)
              (aspWarm . ,asp-warm)
              (nativeWarmP50Ns . ,native-p50)
              (aspWarmP50Ns . ,asp-p50)
              (aspOverNativeP50Ns . ,overhead-ns)
              (nativeWarmCompileCount . ,native-warm-compile)
              (aspWarmCompileCount . ,asp-warm-compile))))
      (write-receipt receipt-path receipt)
      (displayln "[package-spec-native-ab] native-warm-p50-ns=" native-p50
                 " asp-warm-p50-ns=" asp-p50
                 " overhead-ns=" overhead-ns
                 " native-warm-compile=" native-warm-compile
                 " asp-warm-compile=" asp-warm-compile)
      (displayln "[package-spec-native-ab] evidence-root=" run-root
                 " receipt=" receipt-path)
      (force-output)
      (unless (= (sample-ref native-cold 'compileCount) 1)
        (error "native cold lane must compile exactly one target" native-cold))
      (unless (= (sample-ref asp-cold 'compileCount) 1)
        (error "ASP cold lane must compile exactly one target" asp-cold))
      (unless (and (= native-warm-compile 0) (= asp-warm-compile 0))
        (error "warm lanes must compile zero targets"
               native-warm-compile asp-warm-compile))
      (unless (<= overhead-ns +max-overhead-ns+)
        (error "PackageSpec warm overhead exceeded Scenario contract"
               overhead-ns +max-overhead-ns+)))))
