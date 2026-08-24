;;; -*- Gerbil -*-
;;; Project constants shared by command and protocol modules.

(import (only-in :gslph/src/protocol/command-catalog provider-command-help))

(export +language-id+
        +cli-id+
        +provider-id+
        +release-version+
        +semantic-extension-pattern-mapping-schema-id+
        +display-name+
        +help+)
;; String
(def +language-id+ "gerbil-scheme")
;; String
(def +cli-id+ "gslph")
;; String
(def +provider-id+ "asp-gerbil-scheme")
;; String
(def +release-version+ "v0.1.0-67-g20798be")
;; String
(def +semantic-extension-pattern-mapping-schema-id+
  "agent.semantic-protocols.semantic-extension-pattern-mapping")
;; Unit
(def +display-name+ "Gerbil Scheme Harness")
;; ConfigConstant
(def +help+
  (provider-command-help +cli-id+))
