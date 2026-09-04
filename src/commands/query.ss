;;; -*- Gerbil -*-
;;; Provider-native exact projection transport.

(import :asp-gerbil-scheme/src/exact-source-projection
        (only-in :asp-gerbil-scheme/src/protocol/json-output write-json-line)
        (only-in :std/text/json read-json)
        :asp-gerbil-scheme/src/support/args)

(export query-main)

;; Public query discovery and source-rendering flags were removed. ASP owns the
;; public exact-query contract and invokes the provider with one typed request.
;; : (-> (List String) Integer)
(def (query-main args)
  (unless (flag? "--asp-exact-request-stdin" args)
    (error
     "exact source projection is ASP-owned; use asp gerbil-scheme query --selector <exact-structural-selector> --projection source|callable-skeleton --workspace <workspace-root>"))
  (let ((provider-id (option "--asp-provider-id" args))
        (parser-identity-digest
         (option "--asp-parser-identity-digest" args))
        (query-pack-digest (option "--asp-query-pack-digest" args)))
    (unless (and provider-id parser-identity-digest query-pack-digest)
      (error "provider-native exact request requires ASP identity flags"))
    (write-json-line
     (project-provider-native-exact-request
      (read-json (current-input-port))
      provider-id
      parser-identity-digest
      query-pack-digest))
    0))
