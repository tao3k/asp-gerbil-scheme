(import :asp-gerbil-scheme/src/testing/memory-profile)

(def profile
  '((maxHeapMiB . 512)))

(declare-gxtest-memory-exception profile)
