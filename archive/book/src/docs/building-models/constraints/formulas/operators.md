# Formula-Combining Operators

Formula operators combine smaller formulas to produce new formulas. Many closely resemble similar operators from programming languages, like `&&`, `||`, and `!`.

## List of Available Operators:

For the following `<fmla>` means an arbitrary formula.

- Negation: [`not (!)`](./operators.md#not)
- Conjunction: [`and (&&)`](./operators.md#and)
- Disjunction: [`or (||)`](./operators.md#or)
- Implication: [`implies (=>)`](./operators.md#implies)
  - If-then-else: [`else`](./operators.md#implies-else)
- If-and-only-if: [`iff (<=>)`](./operators.md#iff)

```admonish note title="Alternative syntax"
Some operators have alternative syntax (marked by **_alt_**) which are equivalent. Use whichever is most natural and convenient to you. 
```

---
## `not` (_alt:_ `!`)

> `not <fmla>`
> 
> `! <fmla>`

**true** when `<fmla>` evaluates to **false**

```admonish example
If `some p.spouse` is true when the person `p` is married, `not (some p.spouse)` denotes the opposite, being true whenever `p` is _not_ married.
```

---

## `and` (_alt:_ `&&`)

> `<fmla-a> and <fmla-b>`
>
> `<fmla-a> && <fmla-b>`

**true** when both `<fmla-a>` and `<fmla-b>` evaluate to **true**.

```admonish example
If `some p.spouse` is true when the person `p` is married, and `p.spouse != p` is true when `p` is not married to themselves, then `some p.spouse and p.spouse != p` is true exactly when `p` is married, but not to themselves.
```

```admonish note title="Implicit and"
Forge treats consecutive formulas within `{ ... }` as implicitly combined using `and`. For instance, the above example could also be written as:
~~~
{
  some p.spouse
  p.spouse != p
}
~~~
```

---

## `or` (_alt:_ `||`)

> `<fmla-a> or <fmla-b>`
>
> `<fmla-a> || <fmla-b>`

**true** when either `<fmla-a>` is **true** or `<fmla-b>` evaluates to **true**.

```admonish example
If `some p.spouse` is true when the person `p` is married, and `p.spouse != p` is true when `p` is not married to themselves, then `some p.spouse or p.spouse != p` is true exactly when `p` is _either_:
- married; or 
- not married to themselves (including the case where `p` is unmarried).
```

---

## `implies` (_alt_ `=>`)

> `<fmla-a> implies <fmla-b>`
> 
> `<fmla-a> => <fmla-b>`

**true** when either `<fmla-a>` evaluates to **false** or `<fmla-b>` evaluates to **true**.

```admonish example
If `some p.spouse` is true when the person `p` is married, and `p.spouse != p` is true when `p` is not married to themselves, then `some p.spouse implies p.spouse != p` is true exactly when `p` is _either_:
- unmarried; or 
- not married to themselves.
```

---

### `implies else` (_alt:_ `=> else`)

> `{<fmla-a> implies <fmla-b> else <fmla-c>}`
>
> `{<fmla-a> => <fmla-b> else <fmla-c>}`

takes the value of `<fmla-b>` when `<fmla-a>` evaluates to **true**, and takes the value of `<fmla-c>` otherwise.

```admonish example
If:
- `some p.spouse` is true when the person `p` is married, 
- `p.spouse != p` is true when `p` is not married to themselves, and
- `some p.parent1` is true when `p` has a `parent1` in the instance, 

then `some p.spouse => p.spouse != p else some p.parent1` is true exactly when:
- `p` is married, and not to themselves; or
- `p` is not married and have a `parent1` in the instance.
```

---

## `iff` (_alt:_ `<=>`)

> `<fmla-a> iff <fmla-b>`
> 
> `<fmla-a> <=> <fmla-b>`

true when `<fmla-a>` evaluates to **true** exactly when `<fmla-b>` evaluates to **true**.

```admonish note title="IFF"
The term `iff` is short for "if and only if".
```

```admonish example
If `some p.spouse` is true when the person `p` is married, and `some p.parent1` is true when `p` has a `parent1` in the instance, then `some p.spouse iff some p.parent1` is true exactly when _either_:
- `p` is married and has a `parent1` in the instance; or 
- `p` is unmarried has no `parent1` in the instance.
```

---
