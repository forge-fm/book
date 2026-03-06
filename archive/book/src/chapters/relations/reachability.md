# Relations and Reachability

<!-- ~~~admonish note title="Brown CSCI 1710"

* Hopefully everyone has been making good progress with Curiosity Modeling! I'm seeing a lot of awesome questions on Ed and at hours. 
* Some of you are curious about how far you need to go to earn a check on the project. This is hard to give a precise answer to, because everyone's models will be different. However, I can say that we're looking for:
    * evidence that you explored your topic of choice;
    * evidence that you validated your model;
    * something you _got_ from the model (generating or solving puzzles, checking a property, or even just understanding a domain better).
* **There's a lab this week** that focuses on _sets_ and other _relational_ concepts. You'll be exploring automated memory management in Forge. This lab leads directly into the next homework, and is meant to give you useful insight into how these systems work.

~~~ -->

Consider this [small Relational Forge model](reach.frg):

```alloy
#lang forge
sig Person {
    friends: set Person,
    followers: set Person
}
one sig Nim, Tim extends Person {}

pred wellformed {
    -- friends is symmetric (followers might not be)
    all disj p1, p2: Person | p1 in p2.friends implies p2 in p1.friends 
    -- you cannot follow or friend yourself
    all p: Person | p not in p.friends and p not in p.followers
}
run {wellformed} for exactly 8 Person
```

Let's run it, get a reasonably large instance, and try to figure out how to express some goals in the evaluator. 

**EXERCISE**: You'll be following along with each of these questions. Use the evaluator heavily---it's great for figuring out what different expressions evaluate to.

#### Expression: Nim's followers

<details>
<summary>Think, then click!</summary>

This is just `Nim.followers`.

</details>

#### Formula: Nim is reachable from Tim via "followers"

<details>
<summary>Think, then click!</summary>

We can use the `reachable` built-in: `reachable[Nim, Tim, followers]`.

</details>

#### Expression: Nim's followers' followers

<details>
<summary>Think, then click!</summary>

Another application of the field! `Nim.followers.followers`.

But wait, what does this really mean? Since `Nim.followers` is a set, rather than a `Person`, should I be able to apply `.followers` to it? If we try this in the evaluator, it works, but we're no longer just doing a "field access"; something more must be going on. 

</details>


#### Formula: Nim is reachable from Tim via the inverse of "followers" (what we might call "following")?

<details>
<summary>Think, then click!</summary>

Hmm. This seems harder. We don't have a field called `following`, and the `reachable` built-in takes fields! 

...it does take fields, right? Or might it take something more flexible? Can we use _set operations_ to adjust the potential edges that `reachable` looks at?

</details>

To figure that out, let's try something else.

#### Formula: Nim is reachable from Tim via followers, but not including Tim's friends?

<details>
<summary>Think, then click!</summary>

We might try `reachable[Nim, Tim, (followers-Tim.friends)]` but this will produce an error. Why? Well, one reason we might give is:

> ...because `followers` is a field but `Tim.friends` is a set.

But is that the real answer? The error complains about "arity": 2 vs 1. Let's type those two expressions into the evaluator and see what we get. For `followers`, we get a set of _pairs_ of people. But `Tim.friends` is a set of _singletons_. 

</details>

<!-- ~~~admonish warning title="Evaluator Output" 
The evaluator prints expression values as parenthesized lists of lists. But don't be fooled! It's really printing a _set_ of _lists_. The order in which the inner lists print shouldn't matter.
~~~ -->

~~~admonish tip title="Arity, Relations, and Tuples"

_Arity_ is another word for how wide the elements of a set are. Here, we'd say that `followers` has arity 2 since elements of `followers` are pairs of atoms. Similarly, `Tim.friends` has arity 1 since its elements are singletons. So Forge is pointing out that taking the set difference of these two makes no sense; their elements are shaped differently.

When we're talking about sets in this way, we sometimes call them _relations_. E.g., the `followers` field is a _binary relation_ because it has arity 2. We'll call elements of relations _tuples_. E.g., if `Nim` follows `Tim`, the tuple `(Tim, Nim)` would be present in `followers`.
~~~

In Relational Forge, `reachable` doesn't take "fields"; it takes relations. Specifically, binary relations, which define the steps it can use to connect the two objects. That's the fact we'll use to solve the 2 problems above. 

#### (Attempt 2) Formula: Nim is reachable from Tim via the inverse of "followers" (what we might call "following")?

Now that we know `followers` is a binary relation, we can imagine flipping it to get its inverse. How can we do that? Well, there are multiple ways! We could write a set-comprehension:

```
{p1, p2: Person | p1 in p2.followers}
```

The order matters here! If `p1` is in `p2.followers`, then there is an entry in the relation that looks like `(p2, p1)`. We could make this more explicit by writing:

```
{p1, p2: Person | p2->p1 in followers}
```

Now that we know `followers` is a set, this makes sense! The _product_ (`->`) operator combines `p2` and `p1` into a binary tuple, which may (or may not) be in `followers`.

Forge provides an operator that does this directly for binary relations: transpose (`~`). So we could write instead:

```
~followers
```

Which should you use? It's up to you! Regardless, we could now answer this question with:

```alloy
reachable[Nim, Tim, ~followers]
```

#### (Attempt 2) Formula: Nim is reachable from Tim via followers, but not including Tim's friends?

Everything is a set, so let's build the subset of `followers` that doesn't involve anyone in `Tim.friends`. We can't write `followers-(Tim.friends)`, since that's an arity mismatch. Somehow, we need to remove entries in `followers` involving one of Tim's friends _and anybody else_. 

One way is to use the product operator to build the binary relation we want `reachable` to use. E.g.:

```
reachable[Nim, Tim, followers-(Tim.friends->Person)]
```

~~~admonish tip title="" 
You may notice that we've now used `->` in what seems like 2 different ways. We used it to combine specific people, `p1` and `p2` above into a single tuple. But now we're using it to combine two _sets_ into a _set_ of tuples. This flexibility is a side effect of sets being the fundamental concept in Relational Forge:
* the product of `((Tim))` and `((Nim))` is `((Tim, Nim))`; 
* the product of `((Person1), (Person2))` and `((Person3), (Person4))` is `((Person1, Person3), (Person1, Person4), (Person2, Person3), (Person2, Person4))`. 

Formally, `->` is the cross-product operation on sets. 

You'll see this apparently double-meaning when using `in` and `=`, too: singletons are single-element sets, where the element is a one-column tuple.
~~~


## What is Dot, Really? 

In Relational Forge, the dot operator is called _relational join_. The expression `A.B` combines two arbitrary relations `A` and `B` by seeking out rows with common values in their rightmost (in `A`) and leftmost (in `B`) columns. Concretely, if `A` is an $n$-ary relation, and `B` is $m$-ary, then `A.B` equals the $n+m-2$-ary relation:

$$\{a_1, ..., a_{n-1}, b_2, ..., b_m \;| \;\exists x \;|\; (a_1, ..., a_{n-1}, x) \in A \text{ and } (x, b_2, ..., b_m) \in B\}$$

That's a lot, so let's work through some examples. Suppose that we have the following relation for the `friend` field of `Person`:

| column 1  |  column 2 | 
|---------- | --------- |
| `Tim`     | `Person0` |
| `Tim`     | `Person1` |
| `Person0` | `Person1` | 
| `Person0` | `Tim`     | 
| `Person1` | `Person0` | 
| `Person1` | `Person2` |
| `Person1` | `Tim`     | 
| `Person2` | `Person1` | 
| `Person2` | `Nim`     | 
| `Nim`     | `Person2` |

We know that join can often work like field access. So we'd expect `Tim.friend` to produce a set containing `Person0` and `Person1`. Why? Because we see `Tim` in the _left_ column of 2 rows, and the _right_ columns of those rows contain `Person0` and `Person1`. 

But what about each of the following?

~~~admonish tip title="Try the evaluator!"
To build intuition for `.`, try expressions like this in the evaluator after reading the following examples.
~~~

#### `friend.Tim`

Here we run the same process that gave us a value for `Tim.friend`, but in reverse. Which rows do we see `Tim` in the _right_ column? 

<center><img width="40%" src="./Join2.png" style="background-color:white"/></center>

Because `friend` is symmetric, it's the same: `friend.Tim` is the same as `Tim.friend`, a set containing `Person0` and `Person1`. 

---

#### `friend.friend`

Before trying to compute the value, first answer: 

**Exercise:** What is the arity of `friend.friend`?

<details>
<summary>Think, then click!</summary>

Well, `friend` has arity `2`, and a join subtracts one column from each side. So we expect `friend.friend` to have arity `1+1=2`. 

</details>

Now, what's the value? Start by looking for matches. Here are some of them (the ones on `Person0`): 

<center><img width="40%" src="./Join3.png" style="background-color:white"/></center>

Continuing, we'll find matches on `Person1`, `Tim`, and others. Because some people have a lot of friends, the graph is getting difficult to read, but notice what's happening: we're identifying _matching pairs of rows_ in each relation.

<center><img width="40%" src="./Join4.png" style="background-color:white"/></center>

Finally, we generate a new row in the result for every pair of matching rows, deleting the inner columns we matched on: `Tim->Person1` is in the result because `Tim->Person0` is in `friends` (the left-hand side of the join) and `Person0->Person1` is in `friends` (the right-hand side of the join). We'll get one row for every match (but we won't keep duplicates):

| column 1  |  column 2 | 
|---------- | --------- |
| `Tim`     | `Person1` |
| `Tim`     | `Person2` |
| `Tim`     | `Tim`     |
| `Person0` | `Person0` | 
| `Person0` | `Person1` | 
| `Person0` | `Person2` | 
| `Person0` | `Tim`     | 
| `Person1` | `Person0` | 
| `Person1` | `Person1` | 
| `Person1` | `Tim`     |
| `Person1` | `Nim`     | 
| `Person2` | `Person0` | 
| `Person2` | `Person2` | 
| `Person2` | `Tim`     | 
| `Nim`     | `Nim`     |
| `Nim`     | `Person2` |

**This is the set of _friend-of-friend_ relationships.** If we computed `friend.friend.friend`, we'd get the _friend-of-friend-of-friend_ relationships, and so on.

**TODO: double-check this**

---

**Exercise:** What about `Tim.Tim`?

<details>
<summary>Think, then click!</summary>

This will give an error because the result has arity `0`. 

</details>


## How Reachability Works

If we wanted to encode reachability without using the built-in `reachable` predicate, we could start by writing a helper predicate:

```alloy
pred reachable2[to: Person, from: Person, via: Person -> Person]: set Person {
    to in 
    from.via +
    from.via.via +
    from.via.via.via 
    -- ...and so on...
}
```

But we always have to stop writing somewhere. We could write the union out to 20 steps, and still we wouldn't catch some very long (length 21 or higher) paths. So we need some way to talk about _unbounded reachability_, or at least reachability up to a path length that's influenced by the problem bounds.

Forge's `reachable` built-in does this, but it's just a facade over a new relational operator: transitive closure (`^R`).

The _transitive closure_ `^R` of a binary relation `R` is the _smallest_ binary relation such that:
* if `x->y` is in `R`, then `x->y` is in `^R`; and
* if `x->z` is in `R` and `z->y` is in `^R` then `x->y` is in `R`.

That is, `^R` encodes exactly what we were trying to achieve above. The `reachable[to, from, f1, ...]` built-in is just syntactic sugar for:

```alloy
    to in from.^(f1 + ...)
```

You might remember that `reachable` always evaluates to true if we give `none` as its first argument. This is because of the translation above: if `to` is the empty set, then it is a subset of anything. 

<!-- ~~~admonish tip title="Design Discussion"
You might wonder why we don't translate `reachable[to, from, f1, ...]` to something like `to in from.^(f1 + ...) and some to`. This would, after all, fix the problem of `none` being reachable from everything! The answer is that this fix might cause other confusion, and either way the ...
...
~~~ -->
