;;; -*- Gerbil -*-
;;; Public declarative Build API for downstream Gerbil package scripts.

(import ./build-api/builder-profile
        ./build-api/package-spec
        ./build-api/profile-build-spec
        ./build-api/source-discovery
        ./building/build-script)

(export (import: ./build-api/builder-profile)
        (import: ./build-api/package-spec)
        (import: ./build-api/profile-build-spec)
        (import: ./build-api/source-discovery)
        (import: ./building/build-script))
