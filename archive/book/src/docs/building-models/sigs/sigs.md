# Sigs

_Sigs_ (short for "signatures") are the basic building block of any model in Forge. They represent the types of the system being modeled. To declare one, use the `sig` keyword. 

```
sig <name> {}
```

A `sig` can also have one or more _fields_, which define relationships between members of that `sig` other atoms. The definition above has no fields because the braces are empty. In contrast, this `sig` definition would have many fields:

```
sig <name> {
    <field>,
    <field>,
    ...
    <field>
}
```

```admonish note title="Syntax Note"
Ensure that there is a **comma after every field except for the last one**. This is a common source of compilation errors when first defining a model!
```

## Fields

Fields allow us to define relationships between a given `sig`s and other components of our model. Each _field_ in a `sig` has:

- a _**name**_ for the field;
- a [_**multiplicity**_](./multiplicity.md) (`one`, `lone`, `pfunc`, `func`, or, in Relational or Temporal Forge, `set`);
- a _**type**_ (a `->` separated list of `sig` names, including the built-in sig [`Int`](../../forge-standard-library/constants-and-keywords.md))_**.**_

~~~admonish example title="Example sig definition"
Here is a sig that defines the `Person` type from the [overview](../overview.md).
```
sig Person {
    bestFriend: lone Person
}
```
The `lone` [multiplicity](./multiplicity.md) says that the field may contain at most one atom. (Note that this example has yet to express the constraint that everyone has a friend!)
~~~

### More Examples

Let's look at a few more examples.

```admonish example title="Example: Sig with one field"
**Basic Sig with Fields (Linked List):**

A model of a circularly-linked list might have a `sig` called `Node`. `Node` might then have a field `next: one Node` to represent the contents of every `Node`'s `next` reference. We use `one` here since every `Node` always has exactly one successor in a _circularly_ linked list.&#x20;

~~~
sig Node {
    next: one Node
}
~~~
```

```admonish example title="Example: Sig with multiple fields"
**Basic Sig with Fields (Binary Tree):**

A model of a binary tree might have a `sig` called `Node`. `Node` might then have three fields:

- `left: lone Node` and `right: lone Node` to represent the `Node`'s children. We use `lone` here since the left/right child fields can either be empty or contain exactly one `Node`.
- `val: one Int` to represent the value of each Node, where we have decided that every `Node` should have an `Int`eger value. We use `one` here because each `Node` should have exactly one value.

~~~
sig Node {
    left: lone Node,
    right: lone Node,
    val: one Int
}
~~~
_`Int` is a built-in sig provided by Forge. To learn more about how Forge handles integers, see [Integers in Forge](../../forge-standard-library/integers.md)._
```

```admonish example title="Example: Sig with No Fields"

**Example - Basic Sig without Fields:**

Not every `sig` in a model needs to have fields to be a useful part of the model! `sig`s with no fields are often used in conjunction with other `sig`s that reference them. One such example might look like this:

~~~
sig Student {}
sig Group {
    member: set Student
}
~~~

Note that the `set` multiplicity is only available in Relational and Temporal Forge, not Froglet.
```

```admonish warning title="Field names must be unique"
You cannot use the same field name within two different `sigs` in a model. This is because field names are globally available for writing constraints.
```

