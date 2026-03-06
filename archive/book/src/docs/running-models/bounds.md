# Bounds

Forge is a _bounded_ model finder, meaning it can only look for instances up to a certain bound. You can specify bounds in two seperate ways in Forge: using numeric bounds or instance bounds.

---

## Numeric bounds (also called "scopes")

The most basic way of specifying bounds in Forge is providing a maximum number of objects for each `sig`. If no bound is specified, Forge defaults to allowing up to 4 of each `sig`. The default bound on `Int` is a _bitwidth_ of 4 (16 integers total).

Numeric bounds can be provided explicitly per sig in a `run`, `assert`, etc. command by adding a trailing `for ...` after the constraint block (see [Running](running.md)). 

~~~admonish example title="Applying a numeric bound"
E.g., to add a bound to a `run` command in a model with `Cat` and `Dog` sigs, you would write something like:

```
run { ... } for 5 Cat
run { ... } for 5 Cat, 2 Dog
```

The first run will search for instances containing 0--5 cats and 0--4 dogs. The second run will search for instances containing 0--5 cats and 0--2 dogs.

~~~

Note that this sets an **upper** bound on the size of instances Forge will show you. In other words, Forge will search for instances of size **up to** the bound you specify. If you instead want to set an **exact** bound, you can add the `exactly` keyword per sig. You may mix and match exact and upper numeric bounds as desired.

~~~admonish example title="Exact and upper numeric bounds"
```
run { ... } for exactly 5 Cat
run { ... } for exactly 5 Cat, 2 Dog
```

The first run will search for instances containing exactly 5 cats and 0--4 dogs. The second run will search for instances containing exactly 5 cats and 0--2 dogs.

~~~

```admonish warning title="Two Important Exceptions"
Although a numeric bound without `exact` generally means anything **up to** that bound, there are two important exceptions to this rule:

(1) The set of available integers is always fixed exactly by the bitwidth. E.g., `3 Int` corresponds to the 8 integers in the range -4 through 3 (inclusive). 

(2) If the `<field> is linear` annotation is present, the `sig` to which the field belongs will become exact-bounded, even if you have not written `exactly` in the numeric bound.
```

## Instance bounds

Instance bounds allow you to encode specific partial instances that you want Forge to run on. When creating an instance bound, you give upper and lower bounds in terms of concrete objects, not numeric sizes. This allows you to test your predicates on a specific instance, which can be convenient (see [Examples](../testing-chapter/testing.md#examples)). It is also useful for optimization in some cases (see [Partial Instances](./concrete-instance-bounds.md#instances), which use the same bounds syntax as examples). 

~~~admonish example title="A partial instance"
If we have defined a single sig with a single field:
```
sig Person {
    spouse: lone Person
}
```
then this `inst` describes an instance for our model:

```
inst exampleInstance {
    Person = `Person0 + `Person1 + `Person2
    spouse = `Person0 -> `Person1 + `Person1 + `Person0
}
```

Similarly, we could write an example using the same syntax (assuming that `marriageRules` is defined as a predicate):

```
example myExample is {marriageRules} for {
    Person = `Person0 + `Person1 + `Person2
    spouse = `Person0 -> `Person1 + `Person1 + `Person0
}
```
~~~

Note that Forge expects concrete object names to be prefixed with a backquote; this is mandatory, and used to distinguish object names (which only make sense in the context of an instance or instances) from sigs, fields, predicates, and other kinds of identifiers that make sense in arbitrary formulas. 

Instances defined via `inst` can be used in `run`, `assert`, etc. and may be combined with numeric bounds, provided they are consistent. Bounds annotations, such as `is linear`, can be included in instance bounds as well. See the [Concrete Instances](./concrete-instance-bounds.md) section for more information about writing instance bounds.

~~~admonish example title="Using Instance Bounds"
You may give the entire instance bound verbatim:

```
run {} for 3 Int for {
    Person = `Person0 + `Person1 + `Person2
    spouse = `Person0 -> `Person1 + `Person1 + `Person0
}
```

or you may use the instance name directly:

```
run {} for 3 Int for exampleInstance
```

~~~
