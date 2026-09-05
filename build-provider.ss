#!/usr/bin/env gxi
;;; -*- Gerbil -*-

(import (only-in :clan/building init-build-environment!)
        (only-in "./provider-package-spec"
                 asp-gerbil-scheme-provider-spec))

(init-build-environment!
 name: "asp-gerbil-scheme-provider"
 deps: '("clan" "clan/poo")
 spec: (asp-gerbil-scheme-provider-spec))
