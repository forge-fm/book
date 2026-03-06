# Let-Expressions

You can bind an expression to an identifier locally by using a `let` form:

```
let <id> = <expression> |
  <formula>
```

This is useful to avoid code bloat due to re-use. E.g., if `s` is a state:

```
let s2 = Traces.nextState[s] |
  canTransition[s, s2]
```

## Using `let` in the evaluator 

A `let` expression can be useful when debugging a model using Sterling's evaluator. E.g., if you want to evaluate an internal subformula for a specific value of a quantifier:

```
some p: Person | some p.spouse
```

you can check individual values by directly substituting (e.g., `some Person0.spouse`) but this is tiresome if the variable is used in multiple places. Instead, consider using let: 

```
let p = Person0 | some p.spouse
```

~~~admonish warning title="Concrete atoms"
This trick (referring to concrete objects) is only usable in the evaluator, because at that point a specific instance has been identified.
~~~