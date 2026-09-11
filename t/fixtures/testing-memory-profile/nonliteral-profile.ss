(import :asp-gerbil-scheme/build-api)

(def profile
  '((maxHeapMiB . 512)))

(declare-gxtest-memory-exception profile)
