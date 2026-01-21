# Quantifiers

In the following, `<x>` is a variable, `<expr>` is an expression of arity 1, and `<fmla>` is a formula (that can use the variable `<x>`). You can quantify over a unary set in the following ways:

- `some <x>: <expr> | { <fmla> }`: true when `<fmla>` is true for at least one element in `<expr>`; and
- `all <x>: <expr> | { <fmla> }`: true when `<fmla>` is true for all elements in `<expr>`

If you want to quantify over several variables, you can also do the following:

- `some <x>: <expr-a>, <y>: <expr-b> | { <fmla> }`; or
- `some <x>, <y>: <expr> | { <fmla> }`.

The syntax is the same for other quantifiers, such as `all`.

## Complex Quantifiers

Forge also provides 3 additional quantifiers, which encode somewhat richer constraints than the above:

- `no <x>: <expr> | { <fmla> }`: true when `<fmla>` is false for all elements in `<expr>`
- `lone <x>: <expr> | { <fmla> }`: true when `<fmla>` is true for zero or one elements in `<expr>`
- `one <x>: <expr> | { <fmla> }`: true when `<fmla>` is true for exactly one element in `<expr>`

**The above 3 quantifiers (`no`, `lone`, and `one`) should be used carefully.** Because they invisibly encode extra constraints, they do not commute the same way `some` and `all` quantifiers do. E.g., `some x : A | some y : A | myPred[x,y]` is always equivalent to `some y : A | some x : A | myPred[x,y]`, but `one x : A | one y : A | myPred[x,y]` is **NOT** always equivalent to `one y : A | one x : A | myPred[x,y]`. (Why not? Try it out in Forge!)

```admonish warning
Beware combining the `no`, `one`, and `lone` quantifiers with multiple variables at once; the meaning of, e.g., `one x, y: A | ...` is "there exists a **unique pair** `<x, y>` such that `...`". This is different from the meaning of `one x: A | one y: A | ...`, which is "there is a unique `x` such that there is a unique `y` such that ...".
```

## Quantifying Over Disjoint Objects

Sometimes, it might be useful to try to quantify over all pairs of elements in `A`, where the two in the pair are distinct atoms. You can do that using the `disj` keyword, e.g.:

- `some disj x, y : A | ...` (adds an implicit `x != y and ...`); and
- `all disj x, y : A | ...` (adds an implicit `x != y implies ...`)`
