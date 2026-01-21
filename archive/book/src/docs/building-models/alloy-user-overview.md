# Addendum for Alloy Users

All Forge languages (as of January 2024) are restricted versions of Alloy 6, with some added features. 

Relational Forge syntax and semantics are nearly identical to Alloy 5. Similarly, Temporal Forge approximates Alloy 6. There are some minor differences. E.g.:
- All Forge languages eschew the `fact` construct and `sig`-facts in favor of using predicates throughout.
- Forge disallows some complex field declarations. E.g., one cannot write a bijection as `f: A one -> one A`. Instead, Forge fields always have exactly one multiplicity keyword and a product of sig names.
- Forge introduces new [syntax for testing](../testing-chapter/testing.md). It also supports [partial instances](../running-models/concrete-instance-bounds.md) via the `inst` keyword.
- Due to user-experience concerns, we have changed the name of the `after` temporal operator to `next_state`. This avoids confusion due to Alloy (and Forge's) implicit conjunction; the `after` in `A after B` appears at first to be a binary operator, which it is not!
