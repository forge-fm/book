# Bounds and Booleans: How Forge Works

> "The world is everything that is the case. The world is the totality of facts, not of things. The world is determined by the facts, and by these being all the facts."
> 
>  Ludwig Wittgenstein (Tractatus Logico-philosophicus)

## How Does Forge Work?

We've hinted about this a bit in the [past](../qna/static.md), but now we'll go a bit deeper into how Forge works.  

Recall that every `run` (or `test`, or `example`) command defines a _search problem_: find some instance that satisfies the given constraints and is within the given bounds. When you click "Run", Forge compiles this search problem into a _boolean satisfiability problem_, which it then gives to an external boolean solver package.

There are complications, though. The search problem Forge needs to solve is in terms of _atomic objects_: objects of particular types, which can go into sets and relations and so on. In contrast, a boolean problem is in terms of just boolean variables: _atomic truths_ that can be combined with `and`, `or`, etc. Somehow, we need to bridge that gap from object to boolean.

## What Boolean Solvers Understand

As an example of where Forge needs to end up, here's an example of a real problem to pass to a boolean solver. It's in a standard format called DIMACS, and it describes a way to find a solution to the [4-queens puzzle](https://en.wikipedia.org/wiki/Eight_queens_puzzle). There are many other ways to express this problem, but we'll focus on this one. What do you think it's saying, exactly?

??? note "Click to expand the DIMACS problem definition"
    ```
    c DIMACS for 4 queens
    c 
    p cnf 16 84
    1 2 3 4 0
    -1 -2 0
    -1 -3 0
    -1 -4 0
    -2 -3 0
    -2 -4 0
    -3 -4 0
    5 6 7 8 0
    -5 -6 0
    -5 -7 0
    -5 -8 0
    -6 -7 0
    -6 -8 0
    -7 -8 0
    9 10 11 12 0
    -9 -10 0
    -9 -11 0
    -9 -12 0
    -10 -11 0
    -10 -12 0
    -11 -12 0
    13 14 15 16 0
    -13 -14 0
    -13 -15 0
    -13 -16 0
    -14 -15 0
    -14 -16 0
    -15 -16 0
    1 5 9 13 0
    -1 -5 0
    -1 -9 0
    -1 -13 0
    -5 -9 0
    -5 -13 0
    -9 -13 0
    2 6 10 14 0
    -2 -6 0
    -2 -10 0
    -2 -14 0
    -6 -10 0
    -6 -14 0
    -10 -14 0
    3 7 11 15 0
    -3 -7 0
    -3 -11 0
    -3 -15 0
    -7 -11 0
    -7 -15 0
    -11 -15 0
    4 8 12 16 0
    -4 -8 0
    -4 -12 0
    -4 -16 0
    -8 -12 0
    -8 -16 0
    -12 -16 0
    -1 -6 0
    -1 -11 0
    -1 -16 0
    -2 -7 0
    -2 -12 0
    -2 -5 0
    -3 -8 0
    -3 -6 0
    -3 -9 0
    -4 -7 0
    -4 -10 0
    -4 -13 0
    -5 -10 0
    -5 -15 0
    -6 -11 0
    -6 -16 0
    -6 -9 0
    -7 -12 0
    -7 -10 0
    -7 -13 0
    -8 -11 0
    -8 -14 0
    -9 -14 0
    -10 -15 0
    -10 -13 0
    -11 -16 0
    -11 -14 0
    -12 -15 0
    ```


---

Even without parsing it with a computer, the format tells us a lot about what a purely boolean solver understands. Here are a few facts about DIMACS:

* Boolean variables in DIMACS are represented by integers greater than zero. 
* If `p` is a variable, then `not p` is represented as the integer `-p`. 
* Lines starting with a `c` are comments.
* The line `p cnf 16 84` says there are 16 variables and 84 _clauses_. A clause is a set of variables (or negated variables) all combined with `or`. E.g., `4 8 12 -16 0` means `4 or 8 or 12 or (not 16)`. (The `0` is a line-terminator.)
* To satisfy the input, every clause must be satisfied.

A set of constraints expressed as a set of clauses, each of which must hold true, is said to be in _Conjunctive Normal Form_ (CNF). Boolean solvers often expect input in CNF, for algorithmic reasons we'll soon see.

Now that you know how to read the input format, you might be able to see how the boolean constraints work to solve the 4-queens problem. Any ideas?

??? note "Think, then click!"
    There's one variable for every square on the $4 \times 4$ squares. `1 2 3 4` says that there must be a queen somewhere on the first row. `-1 -2` says that if there is a queen at $1,1$ there cannot also be a queen at $1,2$. And so on.

## "The world is that which is the case"

Consider this Forge model and corresponding `run` command:

```forge
abstract sig Person {
  followers: set Person
}
one sig Alice, Bob, Charlie extends Person {}
run {some followers} for exactly 3 Person 
```

How many potential instances are there? Note that there can only ever be exactly 3 people, since `Person` is `abstract`.

??? note "Think, then click!"
    There are always exactly 3 people, and the only relation that can vary is `followers`, which has 2 columns. That means $3^2 = 9$ potential pairs of people, and the field contains a set of those. The set either contains or does not contain each pair. So there are $2^9 = 512$ potential instances.


---

Notice how we reached that number. There are 9 potential pairs of people. 9 potential follower relationships. 9 essential things that may, or may not, be the case in the world. Nothing else.

If you run Forge on this model, you'll see statistics like these:

```
#vars: (size-variables 10); #primary: (size-primary 9); #clauses: (size-clauses 2)
Transl (ms): (time-translation 122); Solving (ms): (time-solving 1)
```

The timing may vary, but the other stats will be the same. The thing to focus on is: 9 `primary variables`. Primary variables correspond to these atomic truths, which in this case is just who follows who in our fixed 3-person world: the number of rows that are potentially in the `followers` relation.

Let's try increasing the size of the world:

```forge
run {some followers} for 4 Person
```

Now we have a 4th person---or rather, we _might_ have a 4th person. When we run, Forge shows:

```
#vars: (size-variables 27); #primary: (size-primary 17); #clauses: (size-clauses 18)
```

We've gone from 9 to 17 primary variables. Why? 

??? note "Think, then click!"
    There is another _potential_ `Person` in the world; the world may be either size 3 or 4. Whether or not this fourth person exists is 1 new Boolean variable. And since there are _4_ potential people in the world, there are now $4^2 = 16$ potential follower relationships. 

    This equals 17 variables.

</br>

This is how Forge translates statements about atoms into statements about booleans. 

## Intermediate Representation: Lower Bounds, Upper Bounds

Not every potential boolean needs to actually be considered, however. You might [remember](../qna/events.md) that annotations like `{next is linear}` or partial instances defined by `example` or `inst` further limit the set of variables before the boolean solver encounters them. To understand this better, let's increase the verbosity setting in Forge. This will let us look at what Forge produces as an intermediate problem description before converting to boolean logic.

```forge
option verbose 5
```

Let's focus on a few lines. First, you should see this somewhere:

```
(univ 20)
```

This tells the compiler that there are 20 potential objects in the world. (Why 20? Because the default bitwidth is 4: that's 16 integers, plus 4 potential people.) These objects get assigned integer identifiers by the compiler. 

!!! warning "3 different meanings"
    This is an unfortunate overlap in the backend solver engine's language: all _atoms_, including atoms of type `Int`, get assigned integers by the engine. Moreover, the boolean solver itself uses integer indexes for boolean variables. **These are not the same thing!**


Next, the compiler gets provided a _lower_ and _upper_ bound for every relation in the model.
* The _lower_ bound is a set of tuples that must always be in the relation.
* The _upper_ bound is a set of tuples that may be in the relation.

For example, here are the bounds on `Int`:

```
(r:Int [{(0) (1) (2) (3) (4) (5) (6) (7) (8) (9) (10) (11) (12) (13) (14) (15)} :: {(0) (1) (2) (3) (4) (5) (6) (7) (8) (9) (10) (11) (12) (13) (14) (15)}])
```

The lower bound comes first, then a `::`, then the upper bound. These singleton tuples containing `0` through `15` are actually the representatives of integers `-8` through `7`. This is an artifact of how the solver process works.

Here's the bound on `Person` and its three sub-`sig`s:

```
(r:Person [{(16) (17) (18)} :: {(16) (17) (18) (19)}])
(r:Alice [{(16)} :: {(16)}])
(r:Bob [{(17)} :: {(17)}])
(r:Charlie [{(18)} :: {(18)}])
```

The lower bound on `Person` contains 3 object identifiers, because there must always be 3 distinct objects (representing our three `one` sigs). There's an object in the upper, but not the lower, bound, because that fourth person may or may not exist. `Alice`, `Bob`, and `Charlie` are exactly set to be those 3 different always-present objects.

Finally, let's look at a field's bounds:

```
(r:followers [(-> none none) :: {(16 16) (16 17) (16 18) (16 19) (17 16) (17 17) (17 18) (17 19) (18 16) (18 17) (18 18) (18 19) (19 16) (19 17) (19 18) (19 19)}])
```

The `followers` relation may be empty, and it may contain any of the 16 ordered pairs of potential `Person` objects.

_Any tuple in the upper bound of a relation, that isn't also in the lower bound, gets assigned a boolean variable._
* If a tuple isn't in the upper bound, it can never exist in an instance---it would always be assigned false---and so we needn't assign a variable.
* If a tuple is in the lower bound, it must always exist in an instance---it would always be assigned true---and so we can again omit a variable.

## From Forge Constraints to Boolean Constraints

Once we know the set of Boolean variables we'll use, we can translate Forge constraints to purely Boolean ones via substitution. Here's an example of how a basic compiler, without optimizations, might work.  Suppose we have the constraint:

```forge
all p: Person | Alice in p.followers
```

There are no `all` quantifiers in Boolean logic. How can we get rid of it?

??? note "Think, then click!"
    An `all` is just a big `and` over the upper bound on `Person`. So we substitute (note here we're using $Person3$ as if it were defined in our model, because it's a _potential_ part of every instance):

    ```forge
    Alice in Alice.followers
    Alice in Bob.followers
    Alice in Charlie.followers
    (Person3 in Person) implies Alice in Person3.followers
    ```

</br>

There are similar rules for other operators: a `some` becomes a big `or`, a relational join becomes a `some`-quantified statement about the existence of a value to join on, which then becomes a big `or`, etc.

## Example optimization: Skolemization

Forge performs a process called _Skolemization_, named after the logician [Thoralf Skolem](https://en.wikipedia.org/wiki/Thoralf_Skolem), to convert specific `some` quantifiers into supplemental relations. 

The idea is: to satisfy a `some` quantifier, some atom exists that can be plugged into the quantifier's variable `x` to make the child formula true. Skolemization reifies that object witness into the model as a new relational constant `$x`. This:

* makes debugging easier sometimes, since you can immediately _see_ what might satisfy the quantifier constraint; and
* sometimes aids in efficiency, especially in a "target poor" environment like an unsatisfiable problem. 

By convention, these variables are prefixed with a `$`. So if you see a relation labeled `$x`, it's a Skolem relation that points to a value for a `some` quantified variable `x`. The relation will grow wider for every `all` quantifier that wraps the `some` quantifier being Skolemized. To see why that happens, suppose that we have a constraint: `all p: Person | all b: Bank | hasAccount[p,b] implies some i: Int | bankBalance[p,b,i]`. This constraint says that if a person has a bank account at a certain bank, there's a balance entered for that account. That balance isn't constant! It's potentially different for every `Person`-`Bank` pairing. Thus, `$i` would have arity 3: 2 for the "input" and 1 for the "output". 

!!! tip "Skolem Depth"
    You can change how deeply `some` quantifiers will get Skolemized by using the `skolem_depth` option in Forge.


<!-- (Forge adds the numeric suffix to help disambiguate variables with the same name.)
`$x_some32783` -->

## Symmetry Breaking

Let's return to the original Followers model:

```forge
abstract sig Person {
  followers: set Person
}
one sig Alice, Bob, Charlie extends Person {}
run {some followers} for exactly 3 Person 
```

We decided it probably had $512$ instances. But does it _really_? Let's hit `Next` a few times, and count! Actually, that sounds like a lot of work. Let's simplify things a bit more, instead:

```forge
abstract sig Person {
  follower: one Person -- changed: replace `set` with `one` 
}
one sig Alice, Bob, Charlie extends Person {}
run {} for exactly 3 Person  -- changed: don't run any predicates
```

Now everybody has exactly one follower. There are still 9 potential tuples, but we're no longer storing _sets_ of them for each `Person`. Put another way, every instance corresponds to an ordered triplet of `Person` objects (Alice's follower, Bob's follower, and Charlie's follower). There will be $3 \times 3 \times 3 = 3^3 = 27$ instances. And indeed, if we click "Next" 26 times, this is what we see. (Whew.) 

Now suppose we didn't name the 3 people, but just had 3 anonymous `Person` objects:

```forge
sig Person {
  follower: one Person
}
run {} for exactly 3 Person  -- changed: no named people
```

The math is still the same: $27$ instances. But now we only get $9$ before hitting the unsat indicator of "no more instances" in the visualizer.

What's going on?

Forge tries to avoid showing you the same instance multiple times. And, if objects are un-named and the constraints can never distinguish them, instances will be considered "the same" if you can arrive at one by renaming elements of the other. E.g., 

```
Person1 follows Person2
Person2 follows Person3
Person3 follows Person1
```

would be considered equivalent to:

```
Person2 follows Person1
Person3 follows Person2
Person1 follows Person3
```

since the individual `Person` atoms are _anonymous_ to the constraints, which cannot refer to atoms by name. We call these instances _isomorphic_ to each other, and say that there is a _symmetry_ between them.  Formally, Forge finds every instance "up to isomorphism". This is useful for:

* increasing the quality of information you get from paging through instances; and
* (sometimes) improving the runtime on problems, especally if solutions are very rare.

This process isn't always perfect: some equivalent instances can sneak in. Removing _all_ equivalent instances turns out to sometimes be even more expensive than solving the problem. So Forge provides a best-effort, low cost attempt based on a _budget_ for adding additional constraints to the problem, specifically to eliminate symmetries.

You can adjust the budget for symmetry breaking via an option:

*  `option sb 0` turns off symmetry breaking; and
*  `option sb 20` is the default.

If we turn off symmetry-breaking, we'll get the expected number of instances in the above run: $27$.

!!! note "Symmetry Breaking != Filtering"
    Forge doesn't just filter instances after they're generated; it _adds_ extra constraints that try to rule out symmetric instances. These constraints are guaranteed to be satisfied by at least one element of every equivalence class of instances. There's a lot of research work on this area, e.g., [this paper](https://kaiyuanw.github.io/papers/paper22-tacas20.pdf) from 2020. It's also important that these extra constraints are a _best effort_ to eliminate duplicates, not a guarantee.



