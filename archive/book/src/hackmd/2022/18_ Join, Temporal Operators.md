# 18: Join, Temporal Operators

###### tags: `Tag(sp22)`

## Logistics and Setup

* If you did create a second anonymous ID, please fill out the anon-ID form that we posted to Ed last night. (If you didn't create a second ID, but filled out the first form, you don't need to fill out the second form. This is just for those who made a new ID, so we can make sure to award points for recent assignments.)
* We're almost done grading curiosity modeling. I'm super happy! Lots of breadth---we're hoping to share a list of short descriptions soon.
* I want to remind everyone that if you got a check-minus, it doesn't mean "not passing"; it doesn't even mean "can't get an A". It means "not A quality work on **this** assignment". Every check-minus should come with feedback that you can use to improve next time. 
* You do not need any check-plusses to get an A. Check-plusses are rare.

Today's notes involve two different topics that _unrelated_. We'll talk about something in base Forge that will help with your current homework. Then we'll transition into more about temporal mode in Forge. 

## The Truth About Dot

Before we go back to temporal mode, I wanted to talk about field access in Forge. Let's go back to the directed-graph model we used before:

```alloy
#lang forge
sig Person {
    friends: set Person,
    followers: set Person
}
one sig Nim, Tim extends Person {}
pred wellformed {
    -- friendship is symmetric
    all disj p1, p2: Person | p1 in p2.friends implies p2 in p1.friends
    -- cannot follow or friend yourself
    all p: Person | p not in p.friends and p not in p.followers
}
run {wellformed} for exactly 5 Person

pred reachableIn1To7Hops[to: Person, from: Person, fld: Person->Person] {
    to in from.fld or
    to in from.fld.fld or
    to in from.fld.fld.fld or 
    to in from.fld.fld.fld.fld or
    to in from.fld.fld.fld.fld.fld or
    to in from.fld.fld.fld.fld.fld.fld or
    to in from.fld.fld.fld.fld.fld.fld.fld 
    --  ... and so on, for any finite number of hops
    --  this is what you use the transitive-closure operator (^) 
    --  or the reachable built-in predicate for.
}
```

We said that chaining field access with `.` allows us to compute reachability in a certain number of hops. That's how `reachableIn1To7Hops` works. 

However, there's more to `.` than this.

### Beyond Field Access

Let's run this model, and open up the evaluator. I'll show the first instance Forge found using the table view:

![](https://i.imgur.com/CXrslMn.png)

We saw that `Tim.friends` produces the set of `Tim`'s friends, and that `Tim.friends.friends` produces the set of `Tim`'s friends' friends. But let's try something else. Enter this into the evaluator:

```
friends.friends
```

This looks like a nonsense expression: there's no object to reference the `friends` field of. But it means something in Forge:

![](https://i.imgur.com/2m2esUg.png)

What do you notice about this result? Recall that this is just a parenthetical way to show a set of tuples: it's got $(Person0, Person0)$ in it, and so on.

<details>
<summary>Think, then click!</summary>
This seems to be the binary relation (set of 2-element tuples) that describes the friend-of-friend relationship. Because we said that friendship is symmetric, everyone who has friends is a friend-of-a-friend of themselves. And so on.
</details>

The `.` operator in Forge isn't exactly field access. It behaves that way in Froglet, but now that we have sets in the language, it's more powerful. It lets us combine relations in a path-like way.

### Relational Join

Here's the precise definition of the _relational join_ operator (`.`):

If `R` and `S` are relations (with $n$ and $m$ columns, respectively), then `R.S` is defined to be the set of $(n+m-2)$-column tuples: $\{(r_1, ..., r_{n-1}, s_2, ..., s_m) |\; (r_1, ..., r_n) \in R, (s_1, ..., s_m) \in S, \text{ and } r_n = s_1 \}$

That is, whenever the inner columns of the two relations line up on some value, their join contains some tuple(s) that have the inner columns eliminated. 

In a path-finding context, this is why `Tim.friends.friends.friends.friends` has one column, and all the intermediate steps have been removed: `Tim` has one column, and `friends` has 2 columns. `Tim.friends` is the $(1+2-2)$-column relation of `Tim`'s friends. And so on: every time we join on another `friends`, 2 columns are removed.  

Let's try this out in the evaluator:

![](https://i.imgur.com/oeZWrIT.png)

![](https://i.imgur.com/B3Hyk8h.png)

Does this mean that we can write something like `followers.Tim`? Yes; it denotes the set of everyone who has `Tim` as a follower:

![](https://i.imgur.com/yVaYWoz.png)

Note that this is very different from `Tim.followers`, which is the set of everyone who follows `Tim`:

![](https://i.imgur.com/MKu2M29.png)

### Testing Our Definition

We can use Forge to validate the above definition, for relations with fixed arity. So if we want to check the definition for pairs of *binary* relations, up to a bound of `10`, we'd run:

```alloy
test expect {
    joinDefinitionForBinary: {
        friends.followers = 
        {p1, p2: Person | some x: Person | p1->x in friends and 
                                           x->p2 in followers}
    } for 10 Person is checked
}
```

Notice that we don't include `wellformed` here: if we did, we wouldn't be checking the definition for _all_ possible graphs.

### Join Errors

Forge will give you an error message if you try to use join in a way that produces a set with _no_ columns:

![](https://i.imgur.com/KOd4CSt.png)

or if it detects a type mismatch that would mean the join is necessarily empty:

![](https://i.imgur.com/lwYeUk3.png)

![](https://i.imgur.com/Uc8n94G.png)

When you see a parenthesized formula in an error like this, you can read it by interpreting operator names in prefix form. E.g., this one means `Int.friends`. (We'll be updating Forge to not show constraints in parenthetical form soon.)

### What's Join Good For?

Suppose you're modeling something like Dijkstra's algorithm. You'd need a weighted directed graph, which might be something like this:

```alloy
sig Node {
    edges: Node -> Int
}
```

But then `edges` has three columns, and you won't be able to use either `reachable` or `^` on it directly. Instead, you can eliminate the rightmost column with join: `edges.Int`, and then use that expression as if it were a `set` field.

## Electrum Mode 

Now we'll shift gears back to temporal mode. 

Let's convert the model from last time into temporal mode. We'll add the necessary options first. Note that options in Forge are usually _positional_, meaning that it is usually a good idea to have options at the beginning unless you want to vary parameters per `run`.

```alloy
#lang forge

option problem_type temporal
option max_tracelength 10
```

Be sure to get the underscores right. Unfortunately, Forge's  current error if you misspell an option name isn't very friendly.
Also, mixing temporal-mode and normal Forge can be tough, since a state-aware model like we had before won't work well in temporal mode.

In temporal mode, we don't have the ability to talk about specific pre- and post-states, which means we have to change the types of our predicates. For `init`, we have:

```alloy
-- No argument! Temporal mode is implicitly aware of time
pred init {
    all p: Process | World.loc[p] = Disinterested
    no World.flags 
}
```

The loss of a state is perhaps disorienting. How does Forge evaluate `init` without knowing which state we're looking at? **In temporal mode, every constraint is evaluated not just about an instance, but also in the context of some _moment in time_**. You don't need to explicitly mention the moment. So `no World.flags` is true if, at the current time, there's no flags raised. 

Similarly, we'll need to change our transition predicates:

```alloy
-- Only one argument; same reason as above
pred raise[p: Process] {
    // pre.loc[p] = Disinterested
    // post.loc[p] = Waiting
    // post.flags = pre.flags + p
    // all p2: Process - p | post.loc[p2] = pre.loc[p2]
    World.loc[p] = Disinterested
    World.loc'[p] = Waiting
    World.flags' = World.flags + p
    all p2: Process - p | World.loc'[p2] = World.loc[p2]
}
```

I've left the old version commented out, so you can contrast the two. Again, the predicate is true subject to an implicit moment in time. **The priming (') operator means "this expression in the next state"**; so if `raise` holds at some point in time, it means there is a specific relationship between the current and next moments.

We'll convert the other predicates similarly, and then run the model:

```alloy
run {
    -- start in an initial state
    init
    -- in every state of the lasso, the next state is defined by the transition predicate
    always trans
}
```

There are some threats to success here (like deadlocks!) but we'll return to those on Friday.

## Running A Temporal Model

When we run, we get this:

![](https://i.imgur.com/LsN0gfB.png)

### New Buttons!

In temporal mode, Sterling has 2 "next" buttons, rather than just one. The "Next Trace" button will hold all non-`var` relations constant, but ask for a new trace that varies the `var` relations. The "Next Config" button forces the non-`var` relations to differ. These are useful, since otherwise Forge is free to change the value of any relation, even if it's not what you want changed. 

### Trace Minimap

In temporal mode, Sterling shows a "minimap" of the trace in the "Time" tab. You can see the number of states in the trace, as well as where the lasso loops back. 

**It will always be a lasso, because temporal mode never finds anything but lassos.**

You can use the navigation arrows, or click on specific states to move the visualization to that state: 

![](https://i.imgur.com/KnLqfJm.png)

Theming works as normal. For the moment, custom visualizer scripts need to visualize a single state at at time.

