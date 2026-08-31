(searchPrime
 (schemaId "agent.semantic-protocols.semantic-search-packet")
 (schemaVersion "1")
 (protocolId "agent.semantic-protocols.semantic-language")
 (protocolVersion "1")
 (languageId "gerbil-scheme")
 (providerId "asp-gerbil-scheme")
 (binary "asp-gerbil-scheme")
 (namespace "agent.semantic-protocols.gerbil-scheme")
 (method "search/prime")
 (projectRoot ".run/extensions-poo-search-prime")
 (view "prime")
 (renderMode "facts")
 (header
  (kind "search-prime")
  (fields
   (parser "core-read-module")
   (files 2)
   (definitions 1)))
 (projectPackage
  (path "gerbil.pkg")
  (name "sample/app")
  (dependencies ("git.cons.io/mighty-gerbils/gerbil-poo"))
  (fields
   (packageManager "gxpkg")
   (sourceScopePolicy ())
   (modularityPolicy ())
   (agentPolicy ())))
 (extensions
  ((providerExtension
    (name "poo")
    (activation "gerbil.pkg")
    (dependencyMode "required")
    (packageManager "gxpkg")
    (package "sample/app")
    (dependencies ("git.cons.io/mighty-gerbils/gerbil-poo"))
    (capabilities ("object-system" "metaobject-protocol" "protocols" "policy-protocol" "macro-governance" "user-override-witness" "inherited-gerbil-utils" "higher-order-control" "typed-combinator-style" "pattern-inheritance")))))
 (nodes
  ((node
    (id "package:sample/app")
    (kind "package")
    (path "gerbil.pkg")
    (fields
     (name "sample/app")
     (packageManager "gxpkg")
     (dependencies ("git.cons.io/mighty-gerbils/gerbil-poo"))))
   (node
    (id "extension:poo")
    (kind "extension")
    (fields
     (name "poo")
     (activation "gerbil.pkg")
     (dependencyMode "required")
     (packageManager "gxpkg")
     (package "sample/app")
     (dependencies ("git.cons.io/mighty-gerbils/gerbil-poo"))
     (capabilities ("object-system" "metaobject-protocol" "protocols" "policy-protocol" "macro-governance" "user-override-witness" "inherited-gerbil-utils" "higher-order-control" "typed-combinator-style" "pattern-inheritance"))))
   (node
    (id "owner:src/main.ss")
    (kind "owner")
    (path "src/main.ss")
    (rank 1)
    (fields
     (package "sample/app/main")
     (definitions 1)
     (imports 0)
     (includes 0)))
   (node
    (id "owner:gerbil.pkg")
    (kind "owner")
    (path "gerbil.pkg")
    (rank 2)
    (fields
     (package "sample/app")
     (definitions 0)
     (imports 0)
     (includes 0)))))
 (edges
  ((edge
    (from "package:sample/app")
    (kind "activates")
    (to "extension:poo"))
   (edge
    (from "package:sample/app")
    (kind "owns")
    (to "owner:src/main.ss"))
   (edge
    (from "package:sample/app")
    (kind "owns")
    (to "owner:gerbil.pkg"))))
 (owners
  ((owner
    (path "src/main.ss")
    (role "source")
    (public #t)
    (exports ())
    (fields
     (package "sample/app/main")
     (definitions 1)
     (imports 0)
     (includes 0)))
   (owner
    (path "gerbil.pkg")
    (role "source")
    (public #t)
    (exports ())
    (fields
     (package "sample/app")
     (definitions 0)
     (imports 0)
     (includes 0)))))
 (hits
  ((hit
    (kind "owner")
    (ownerPath "src/main.ss")
    (location
     (path "src/main.ss")
     (lineRange "2:2"))
    (score 1)
    (reason "ranked-owner")
    (fields
     (package "sample/app/main")
     (definitions 1)
     (imports 0)
     (includes 0)))
   (hit
    (kind "owner")
    (ownerPath "gerbil.pkg")
    (location
     (path "gerbil.pkg")
     (lineRange "1:1"))
    (score 2)
    (reason "ranked-owner")
    (fields
     (package "sample/app")
     (definitions 0)
     (imports 0)
     (includes 0)))))
 (findings ())
 (nextActions
  ((nextAction
    (kind "search")
    (target "lexical")
    (scope ".run/extensions-poo-search-prime")
    (fields
     (command "asp-gerbil-scheme search lexical '<term>' owner tests --workspace . --view seeds")))))
 (notes
  ((note
    (kind "parser")
    (message "core-read-module native Scheme reader facts")))))
