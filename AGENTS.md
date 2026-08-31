# ASP Gerbil Scheme Agent Instructions

This directory maintains the Gerbil Scheme language project harness. In addition to the repository root instructions, agents working here must follow the local style contract:

@docs/50-59-policy/51.05-current-project-programming-style.org

## Required Style Rules

- Start policy work from parser-owned facts and ASP evidence. Do not use broad source scans, source-name heuristics, or downstream project names as policy triggers.
- Every new style rule needs a scenario under `t/scenarios/policy`, benchmark metadata, a focused policy test, and aggregate suite wiring.
- Gerbil metaprogramming should teach the smallest correct tier: `defrules` / `syntax-rules` for fixed structural rewrites, `defsyntax` / `syntax-case` for validation and identifier generation, syntax parameters or `syntax-local-value` for phase-owned shared metadata.
- Use the style document's advanced Gerbil feature map before writing or changing style policy. Prefer real Gerbil mechanisms such as match macros, syntax parameters, compile-time metadata, generic/interface dispatch, parser generators, source-aware macros, and specialized caches over basic Scheme rewrites when they match the problem shape.
- POO-related repairs must preserve POO-native shape. Do not replace stable `.def`, `.o`, `.ref`, `.mix`, slot operators, or prototype composition with ad hoc alists or hashes except at explicit projection boundaries.
- Reference examples may point at `gerbil://`, `gerbil-utils`, or `gerbil-poo`, but they are learning sources rather than required downstream dependencies.
- If a policy warning fires, repair the source shape or parser facts first. Do not add allow-lists or suppressions as the primary fix.
