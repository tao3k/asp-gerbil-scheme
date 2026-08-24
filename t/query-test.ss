;;; -*- Gerbil -*-
;;; Breaking gate for the ASP-owned exact projection boundary.

(import :gerbil/gambit
        :std/test
        :gslph/src/commands/query
        (only-in :gslph/src/testing/execution-profile
                 declare-gxtest-serial))
(export query-test)

(declare-gxtest-serial shared-native-provider)

(def (query-route-rejected? args)
  (with-catch
   (lambda (_) #t)
   (lambda ()
     (query-main args)
     #f)))

(def query-test
  (test-suite "gerbil scheme harness exact query boundary"
    (test-case "public code facade is physically unsupported"
      (check
       (query-route-rejected?
        ["--selector"
         "gerbil-scheme://src/parser/selectors.ss#item/def/selector-from"
         "--workspace"
         "."
         "--code"])
       => #t))
    (test-case "public names-only facade is physically unsupported"
      (check
       (query-route-rejected?
        ["src/parser/selectors.ss"
         "--term"
         "selector-from"
         "--workspace"
         "."
         "--names-only"])
       => #t))))
