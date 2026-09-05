;;; -*- Gerbil -*-
;;; Breaking gate for the ASP-owned exact projection boundary.

(import :gerbil/gambit
        :std/test
        (only-in :asp-gerbil-scheme/src/runtime/provider-http-json-command-client
                 provider-http-json-query-main)
        (only-in :asp-gerbil-scheme/src/testing/execution-profile
                 declare-gxtest-serial))
(export query-test)

(declare-gxtest-serial shared-native-provider)

(def (query-route-rejected? args)
  (with-catch
   (lambda (_) #t)
   (lambda ()
     (provider-http-json-query-main args)
     #f)))

(def query-test
  (test-suite "gerbil scheme HTTP query boundary"
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
