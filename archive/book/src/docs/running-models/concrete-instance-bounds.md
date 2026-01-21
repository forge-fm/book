# Concrete Instance Bounds

The types of problems that Forge creates and solves consist of 3 mathematical objects:

- A set of signatures and relations (the **language** of the problem);
- A set of logical/relational formulas (the **constraints** of the problem);
- A set of bounds on sigs and relations (the **bounds** of the problem).

## Partial Instances

Forge presents a syntax that helps users keep these concerns separated. The first two concerns are represented by `sig` and `pred` declarations. The third concern is often addressed by numeric bounds (also called "scope"), but numeric bounds are always converted (usually invisibly to the user!) into set-based bounds that concretely specify:
- the _lower_ bounds, what _must_ be in an instance; and 
- the _upper_ bounds, what _may_ be in an instance.

The `inst` syntax provides the ability to manipulate these set-based bounds directly, instead of indirectly via numeric bounds. The same syntax is used in `example` tests. Because bounds declarations interface more directly with the solver than constraints, at times they can yield performance improvements.

Finally, because bounds declarations can concretely refer to atoms in the world, we will often refer to them as _partial instances_.

## `inst` Syntax

An `inst` declaration contains a `{}`-enclosed sequence of bind declarations.  A bind declaration is one of the following, where `A` is either a sig name or field name.

- `#Int = k`: use bitwidth `k` (where `k` is an integer greater than zero); 
- `A in <bounds-expr>`: specify _upper_ bounds on a sig or field `A`;
- `A ni <bounds-expr>`: specify _lower_ bounds on a sig or field `A`;
- `A = <bounds-expr>`: _exactly_ specify the contents of the sig or field `A` (effectively setting both the lower and upper bounds to be the same);
- `no A`: specify that `A` is empty;
- `r is linear` : use bounds-based symmetry breaking to make sure field `r` is a linear ordering on its types (useful for optimizing model-checking queries in Forge); and
- `r is plinear` : similar to `r is linear`, but possibly not involving the entire contents of the sig. I.e., a total linear order on `A'`->`A'` for some subset `A'` of `A`.

When binding fields, the binding can also be given _piecewise_ per atom. Keep in mind that atom names should be prefixed by a backquote:
- `AtomName.f in <bounds-expr>` (upper bound, restricted to `AtomName`);
- `AtomName.f ni <bounds-expr>` (lower bound, restricted to `AtomName`);
- `AtomName.f = <bounds-expr>` (exact bound, restricted to `AtomName`); and
- `no AtomName.f` (exact bound _contains nothing_, restricted to `AtomName`).
Piecewise bindings add no restrictions to _other_ atoms, only those mentioned. They can improve readability if you're defining a field for many different atoms. There is an example below.

The specifics of `<bounds-expr>` depend on which Forge language you are using. 

~~~admonish warning title="Bounds aren't the same as constraints!"
The syntax of partial `inst`ances is very similar to the syntax you use to write constraints in `pred`icates. Always keep in mind that **they are not the same**; bindings have a far more restrictive syntax but allow you to refer to atoms directly---something constraints don't allow. 
~~~

### Froglet Style Bind Expressions 

In Froglet:
- a `<bounds-expr>` for a `sig` is a `+`-separated list of atom names (each prefixed by backquote), `sig` names that have already been bounded, and integers (without backquotes).
- a `<bounds-expr>` for a field is a `+`-separated list of entries in that field, using atom names (each prefixed by a backquote), `sig` names that have already been bounded, and integers (without backquotes). Entries are defined using the `(arg1, arg2, ...) -> result` syntax, and may be either complete or piecewise. 
    - a _complete_ bind for a field 

~~~admonish example title="Froglet-style bounds"
Suppose you have a Forge model like this:
```
sig Person {
    gradeIn: pfunc Course -> Grade
}
sig Course {}
abstract sig Grade {}
```
where `Person` has a partial-function field `gradeIn`, indicating which grade they got in a given course (if any).

Given this concrete bound for the `Person`, `Course`, and `Grade` `sig`s:
```
Person = `Person0 + `Person1 + `Person2
Course = `Course0 + `Course1 + `Course2
Grade = `A + `B + `C 
```
you might define bounds for the `gradeIn` field of `Person` all at once, for everyone:
```
gradeIn = (`Person0, `Course0) -> `A + 
          (`Person0, `Course1) -> `B + 
          (`Person1, `Course2) -> `C
```

or piecewise, one `Person` at a time:

```
`Person0.gradeIn = `Course0 -> `A + 
                   `Course1 -> `B
`Person1.gradeIn = `Course2 -> `C
no `Person2.gradeIn
```
Note that in the piecewise version, we need to explicitly say that `\`Person2` hasn't taken courses; in the all-at-once version, that's implicit.

*This model is available in full [here](../example-models/piecewise-bounds.frg).*
~~~


~~~admonish warning title="Atom names"
Identifiers prefixed by a backquote (`\`) always denote atom names. You cannot name atoms like this in ordinary constraints! (Thus, in the example above there is no `one sig A extends Grade {}`; there is only the atom `\`A`.)
~~~


~~~admonish warning title="`in` vs. `ni` vs. `=`"
Bound expressions must not mix the `=`, `in` and `ni` operators for the same `sig` or field, even within a piecewise definition. It's OK to use `ni` for one field and `in` for another, but always use exactly one of them for each field. You should also not mix operators between sigs that are related by `extends`.
~~~

**This style of bind expression is still allowed in Relational Forge, so if you prefer it, feel free to continue using it!** 

### Relational-Forge Style Bind Expressions

From the relational perspective, a `<bounds-expr>` is a union (`+`) of products (`->`) of object names (each prefixed by backquote), `sig` names, and integers. Bounds expressions must be of appropriate arity for the sig or field name they are bounding. 

~~~admonish example title="Relational bounds expressions"
```
A = `Alice+`Alex+`Adam
f = `Alice->`Alex + 
    `Adam->`Alex
g in `Alice->2 
```
where `A` is a sig, `f` is a field of `A` with value in `A`, and `g` is a field of `A` with integer value. Note that integers should be used directly, without backquotes.
~~~

~~~admonish hint title="Common errors"
**Arity mismatches between the left and right-hand sides.** E.g., in a standard directed graph where `edges` is a binary relation on `Node`s:
```
edges in Node
```
would produce an error, even though the way you declare the field in Forge hides the extra column in the relation:
```
sig Node { edges: set Node }
```

**Leaving parent `sig`s unbounded.** Forge currently (January 2024) will not permit binding a child `sig` without first binding its parent `sig`. E.g., this results in an error if `Student` is a child `sig` of `Person`:
```
Student = `Student0 + `Student1
```
To fix the problem, just add the same kind of bound for `Person`:
```
Student = `Student0 + `Student1
Person = Student + `Teacher0
```
~~~

### `inst` in Temporal Forge

Temporal Forge also supports `inst` using the same syntax above. 

~~~admonish warning title="Bounds apply to all states at once!"
If you use a partial instance with a Temporal Forge model, be aware that there's no way to bind sigs or fields _per state_. Each binding is applied globally, so they can be very useful for optimization, but don't try to write `example`s with `inst` in Temporal Forge---you have no recourse to temporal operators in binding expressions!
~~~

## Notes on Semantics

Bounds declarations are resolved _in order_ before the problem is sent to the solver. The right-hand side of each declaration is evaluated given all preceding bounds declarations, which means that using `sig` names on the right-hand side is allowed so long as those sigs are _exact bounded_ by some preceding bounds declaration. 

A bounds declaration cannot define bounds for a sig unless bounds for its ancestors are also defined. Bounds inconsistencies will produce an error message.

### Mixing Numeric Scope and `inst`

You can mix both styles; just give the set-based bounds after the numeric ones. 

~~~admonish example title="Example `run` mixing both styles"
```
run {myPred} for 5 Person for {Class = `Class0 + `Class1}
```
~~~

However, beware of inconsistencies! Numeric and `inst` bounds are (as of January 2024) only reconciled right before the solver is invoked, so you might receive confusing error messages of "last resort" in case of inconsistency between the two. 



<!-- The semantics of comparison commands using `=`, `in`, or `ni` are asymmetrical.  -->

