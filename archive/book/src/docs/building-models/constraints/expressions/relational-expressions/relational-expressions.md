# Relational Operators

_Relational Operators_ produce expressions (not formulas) from other expressions. 

~~~admonish note title="Froglet"
If you are using Froglet, not all of these operators are available. 
~~~

~~~admonish warning title="Relational Forge" 
Recall that Forge treats every field of a sig as a relation of arity 1 higher than the arity of the field itself, with the object the field belongs to as the added left-most column. E.g., in this sig definition:
```
sig City {
    roads: set City
}
```
the relation `roads` is an arity-2 set which contains ordered pairs of `City` objects.

This is what allows the dot operator in Forge to act as if it is field access when it is actually a [relational join](./relational-expressions.md#-join).
~~~

### List of Relational Expression Operators:

- [`+ (union)`](./relational-expressions.md#-union)
- [`- (set difference)`](./relational-expressions.md#--set-difference)
- [`& (intersection)`](./relational-expressions.md#intersection)
- [`.  [] (relational join)`](./relational-expressions.md#-and--relational-join)
- [`-> (cross product)`](./relational-expressions.md#--cross-product)
- [`~ (transpose)`](./relational-expressions.md#-transpose)
- [`^ (transitive closure)`](./relational-expressions.md#-transitive-closure)
- [`* (reflexive transitive closure)`](./relational-expressions.md#-reflexive-transitive-closure)
- [`=> else`](./relational-expressions.md#if-then-else)
- [`set comprehension`](./relational-expressions.md#set-comprehension)
<!-- (Unlike [Formula Operators](../../formulas/operators.md), the parentheticals are _not alternative syntax_. They are the mathematical names) -->

---

## `+ (union)`

> `<expr-a> + <expr-b>`

returns the **union** of the two exprs, i.e., the set containing all elements that are in either of the two exprs.

```admonish example title="Union"
The set of employees who work at Brown CS include both faculty and staff:
~~~
BrownCS.employees = BrownCS.faculty + BrownCS.staff
~~~
```

---

## `- (set difference)`

> `<expr-a> - <expr-b>`

returns the **set difference** of the two exprs, i.e., everything in `expr-a` that is **not** also in `expr-b`.

```admonish example title="Difference"
The set of students eligible to UTA includes all students except those who are already hired as head TAs:
~~~
BrownCS.utaCandidates = Student - BrownCS.htaHires
~~~
```

---

## `& (intersection)`

> `<expr-a> & <expr-b>`

returns the **intersection** of the two exprs, i.e., all elements in both `expr-a` and `expr-b`.

```admonish example title="Intersection"
Students in the "AI/ML" pathway must take multiple intermediate courses. In this (oversimplified) example, students can use the AI/ML pathway if they've taken both linear algebra and probability:
~~~
BrownCS.canUseAIML = BrownCS.tookLinearAlgebra & BrownCS.tookProbability 
~~~
```

---

## `-> (cross product)`

> `<expr-a> -> <expr-b>`

returns the **cross product** of the two exprs. 

```admonish example title="Product (example 1)"
If `roads` is a binary relation between `City` and itself, and `Providence` and `Pawtucket` are cities:
~~~
sig City {
    roads: set City
}
one sig Providence, Pawtucket extends City {}
~~~
then `Providence -> Pawtucket` is an arity-2, one-element set, which can be used with other operators. E.g.,  `roads + (Providence -> Pawtucket)` represents the set of roads augmented with a new road (if it wasn't already there). 

Likewise, `City -> City` will produce an arity-2 set containing every possible pair-wise combination of cities.
```

---

## `~ (transpose)`

> `~<expr>`

returns the transpose of `<expr>`, assuming it is has arity 2. (Attempting to use transpose on a different-arity relation will produce an error.)

```admonish example title="Transpose"
If `roads` is a binary relation between `City` and itself:
~~~
sig City {
    roads: set City
}
~~~
then `~roads` is an arity-2, set that contains exactly the same elements in `roads` except reversed. E.g., if `Providence -> Pawtucket` was in `roads`, then `Pawtucket -> Providence` would be in `~roads`.
```
---

## Set Comprehension

A set-comprehension expression `{x1: T1, ..., xn: Tn | <fmla>}` evaluates to a set of arity-n tuples. A tuple of objects `o1, ... on` is in the set if and only if `<fmla>` is satisfied when `x1` takes the value `o1`, etc. 

~~~admonish example title="Set Comprehension"
In a model with sigs for `Student`, `Faculty`, and `Course`, the expression
```
{s: Student, i: Faculty | some c: Course | { some s.grades[c] and c.instructor = i} }
``` 
would evaluate to the set of student-faculty pairs where the student has taken a course from that faculty member.
~~~

---

## `.` _and_ `[] (relational join)`

> `<expr-a> . <expr-b>`

returns the **relational join** of the two exprs. It combines two relations by seeking out rows with common values in their rightmost and leftmost columns. Concretely, if `A` is an $n$-ary relation, and `B` is $m$-ary, then `A.B` equals the $n+m-2$-ary relation:

$$\{a_1, ..., a_{n-1}, b_2, ..., b_m | \exists x | (a_1, ..., a_{n-1}, x) \in A \text{ and } (x, b_2, ..., b_m) \in B\}$$

```admonish example title="Product (example 1)"
If `roads` is a binary relation between `City` and itself, and `Providence` is a city:
~~~
sig City {
    roads: set City
}
one sig Providence extends City {}
~~~
then `roads.roads` is an arity-2 set and `Providence.roads` is an arity-1 set. 

In the instance:
~~~
inst joinExample {
    City = `Providence + `City0 + `City2
    roads = `Providence -> `City0 +
            `City0 -> `City1 +
            `City1 -> Providence
}
~~~
`roads.roads` would contain:
~~~
`Providence -> `City1   (because `Providence -> `City0 and `City0 -> `City1)
`City0 -> `Providence (because `City0 -> `City1 and `City1 -> `Providence)
`City1 -> `City0 (because `City1 -> `Providence and `Providence -> `City0)
~~~
`Providence.roads` would contain:
~~~
`City0 (because `Providence -> `City0)
~~~
```

```admonish warning title="Forge is not SQL"
Relations in Forge don't have column _names_ like they do in most databases. The join is always on the innermost columns of the two relations being joined.
```

<!-- [TODOLINK]() -->



**Alternative syntax:** `<expr-a>[<expr-b>]`: is equivalent to `<expr-b> . <expr-a>`;



---

## `^ (transitive closure)`

> `^<expr>`

returns the transitive closure of `<expr>`, assuming it is has arity 2. Attempting to apply `^` to a relation of different arity will produce an error. The transitive closure of a binary relation $r$ is defined as the _smallest_ relation $t$ such that:
- `r in t`; and 
- for all `a`, `b`, and `c`, if `a->b` is in `t` and `b->c` is in `t`, then `a->c` is in `t`.

Informally, it is useful to think of `^r` as encoding _reachability_ using `r`. It is equivalent to the (unbounded and thus inexpressible in Forge) union: `r + r.r + r.r.r + r.r.r.r + ...`. 

```admonish example title="Transitive Closure"
If `roads` is a binary relation between `City` and itself, and `Providence` is a city:
~~~
sig City {
    roads: set City
}
one sig Providence extends City {}
~~~
then `^roads` is the _reachability relation_ between cities.
```

---

## `* (reflexive transitive closure)`

> `*<expr>`

returns the reflexive-transitive closure of `<expr>`, assuming it is has arity 2. Attempting to apply `*` to a relation of different arity will produce an error.

For a given 2-ary relation `r`, `*r` is equivalent to `^r + iden`. 

---

## `if then else`

> `{<fmla> => <expr-a> else <expr-b>}` 

returns `<expr-a>` if `<fmla>` evaluates to true, and `<expr-b>` otherwise.

---

## Caveats: Alloy support

Forge does not currently support the relational Alloy operators `<:`, `:>`, or `++`; if your models require them, please contact the Forge team.
