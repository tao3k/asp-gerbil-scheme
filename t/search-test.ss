;;; -*- Gerbil -*-
;;; Boundary:
;;; - Top-level search-test only composes smaller test owners.
;;; - Keep parser-visible test complexity below modularity thresholds.

(import :std/test
  "./unit/search/search-test-part1"
  "./unit/search/search-test-part2"
  "./unit/search/search-test-part3"
  "./unit/search/search-test-part4"
  "./unit/search/search-test-part5"
  "./unit/search/search-test-part6"
  "./unit/search/search-test-part7"
  "./unit/search/search-test-part8"
  "./unit/search/search-test-part9"
  "./unit/search/search-test-part10"
  "./unit/search/search-test-part11"
  "./unit/search/search-test-part12"
  "./unit/search/search-test-part13"
  "./unit/search/search-test-part14"
  "./unit/search/search-test-part15"
  "./unit/search/search-test-part16"
  "./unit/search/search-test-part17"
  "./unit/search/search-test-part18"
  "./unit/search/search-test-part19"
  "./unit/search/search-test-part20"
  "./unit/search/search-test-part21"
  "./unit/search/search-test-part22"
  "./unit/search/search-test-part23"
  "./unit/search/search-test-part24")
(export search-test)
;; TestSuite
(def search-test
  (test-suite "gerbil scheme harness search"
    search-test-part-1
    search-test-part-2
    search-test-part-3
    search-test-part-4
    search-test-part-5
    search-test-part-6
    search-test-part-7
    search-test-part-8
    search-test-part-9
    search-test-part-10
    search-test-part-11
    search-test-part-12
    search-test-part-13
    search-test-part-14
    search-test-part-15
    search-test-part-16
    search-test-part-17
    search-test-part-18
    search-test-part-19
    search-test-part-20
    search-test-part-21
    search-test-part-22
    search-test-part-23
    search-test-part-24))
