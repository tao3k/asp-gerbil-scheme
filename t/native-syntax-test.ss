;;; -*- Gerbil -*-
;;; Provider-native parser facts consumed by the ASP Search playbook.

(import :std/test
        "./unit/search/structural-index")

(export native-syntax-test)

(def native-syntax-test
  (test-suite "gerbil scheme native syntax facts"
    (test-case "native index has the required envelope"
      (check-structural-index-required-envelope))
    (test-case "native index exposes queryable parser facts"
      (check-structural-index-queryable-facts))
    (test-case "native index preserves quality-shape facts"
      (check-structural-index-quality-shape-facts))
    (test-case "native index preserves dependency adapter facts"
      (check-structural-index-dependency-adapter-facts))))
