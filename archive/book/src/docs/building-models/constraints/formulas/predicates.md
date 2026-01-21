# Predicates

If you have a set of constraints that you use often, or that you'd like to give a name to, you can define a _predicate_ using the `pred` keyword. A predicate has the following form:

```
pred <pred-name> {
   <fmla-1>
   <fmla-2>
   ...
   <fmla-n>
}
```

Newlines between formulas in a `pred` will be combined implicitly with `and`s, helping keep your predicates uncluttered. Predicates can also be defined with arguments, which will be evaluated via substitution. For instance, in a family-tree model, you could create:

```
pred parentOrChildOf[p1, p2: Person] {
  p2 = p1.parent1 or
  p2 = p1.parent2 or
  p1 = p2.parent1 or
  p1 = p2.parent1
}
```

and then write something like `some p : Person | parentOrChildOf[Tim, p]`. Predicates may be used like this anywhere a formula can appear.

