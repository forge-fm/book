# Constants & Keywords

## Constants

Forge provides a few built-in constants:

- `univ` (arity 1): the set of all objects in the universe (including `Int`s);
- `none` (arity 1): the empty set (to produce higher-arity empty relations, use the `->` operator. E.g., a 2-ary empty relation would be represented as `none -> none` 
);
- `iden`: the identity relation (a total function from all objects in the universe to themselves, including `Ints`);
- `Int`: the set of available integer objects. By default it contains `-8` to `7` inclusive, since the default bitwidth is `4`. See [Integers](../forge-standard-library/integers.md) for more information.

## Keywords

The following is a list of keywords in Forge that may not be used as names for relations, sigs, predicates, and runs. These include:
- `state`, `transition` (reserved for future use)
- `sig`, `pred`, `fun`
- `test`, `expect`, `assert`, `run`, `check`, `is`, `for`
- names of arithmetic operators, helpers, and built-in constants (e.g., `add`, `univ`, and `reachable`)