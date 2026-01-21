# Linear Temporal Logic

Formally, the temporal operators Forge provides come from a language called Linear Temporal Logic (or LTL). It's _temporal_ because it has time-aware operators like `always` and `eventually`, and it's _linear_ because it's interpreted over (infinite) linear traces. 

~~~admonish note title="Industrial Practice"
LTL is commonly used in industry. And even where it isn't used directly, many other temporal specification languages are either related to LTL (e.g., branching-time logics like CTL) or inspired by it (e.g., Lamport's [$TLA^{+}$](https://lamport.azurewebsites.net/tla/tla.html) and other more recent languages). There are a _lot_ of industrial model-checking tools out there, using a lot of different languages, but learning LTL will help you build intuition for nearly all of them.

And, on the research side of things, there's a lot of temporal logic use as well. For example, [this paper](https://nakulgopalan.github.io/docs/sequence-sequence-language.pdf) on using temporal logics in AI to specify robot behaviors.
~~~

## How To Read A Temporal Formula

Recall that:
* time is _implicit_ in temporal mode, and 
* temporal mode only ever finds lasso traces. 

When you write a constraint in temporal mode, it's true with respect to an instance (which is always a lasso trace) _and a time index_ into that trace. Thus the `init` predicate may be true, or not true, depending on which state you're looking at.

Evaluation always _starts_ at the first state. This corresponds to the top-level `run` command or `test`. I didn't say "the initial state", because if we've got a predicate that encodes "initial state", it  won't be enforced unless we've told Forge to do so. This is why, usually, you'll start by putting: `init` (or whatever your initial-state predicate is named) in your top-level `run`. 

As soon as temporal operators become involved, however, the "evaluate in the first state" rule starts to change because the current time index may change.

## Moving Forward In Time

You can refer to the _next_ state (relative to the current one, whatever it is) by using the `next_state` operator. If I wanted to say that the _second_ and _third_ states would also need to be initial states, I'd write more in the top-level `run` block:

```
init
next_state init
next_state next_state init
```

It's rare you'd do something like this in practice, but it's a good first demonstration of the operator.

~~~admonish note title="Why `next_state`?"
The keyword is, admittedly, a little verbose. But it was the best of the various candidates at hand:
* In many settings, this LTL operator is usually called `X`, which is not very descriptive. (When I read `X`, I think "variable"!)
* In Forge's parent language, Alloy 6, the operator is called `after`, but this can lead to some misconceptions since `A after B` might be misinterpreted as a binary operator, and Forge and Alloy both have implicit `and` via newlines, so `A after B` would actually mean `A and (after B)`. 
* I've heard `afterward` suggested, but that risks confusion with `always` or `eventually`.
~~~

## Quantifying Over Time

What does it mean for something to `always` be true, or to `eventually` hold? These terms quantify over time: if something is `always` true, it's true at all time indexes (starting now). If something is `eventually` true, it's true at _some_ time index (possibly now). 

So if we wanted to say that every state in the trace transitions to its successor in accordance with our `move` predicate, we'd say: `always move`. In the last section, because we had multiple predicates, and each took an argument, we wrote:

```forge
always {some t: Thread | raise[t] or enter[t] or leave[t]}
```

### Nesting Operators

Just like you can nest `all` and `some`, you can nest `always` and `eventually`. We'll need to do this to express properties like non-starvation. In fact, let's think about how to express non-starvation now! 

We had informally written non-starvation in our mutex model as something like "once a process becomes interested, it eventually gets access". How would you write this using temporal operators, assuming that `interested` and `access` were predicates describing the process becoming interested and getting access respectively?

**Exercise:** Try this!

<details>
<summary>Think, then click for a possible solution.</summary>

We might start with: `interested => eventually access`. That would be a reasonable start: if the process is interested, it eventually gets access. The problem is that the interest is measured _now_---that is, at whatever time index Forge is currently looking. 

</details>

---

Clearly we need to add some sort of temporal operator that prevents the above issue. Here's a possible candidate: `(eventually interested) => (eventually access)`. 

**Exercise:** What's wrong with this one?

<details>
<summary>Think, then click!</summary>

The problem here is that there's no connection between the time at which the left-hand side holds, and the time at which the right-hand side holds. To force that relationship (access _after_ interest) we need to nest the two temporal quantifiers.

</details>

---

How about `eventually (interested => (eventually access))`? 

<details>
<summary>Think, then click!</summary>

This constraint isn't strong enough. Imagine a trace where the process never gets access, but is interested only (say) half the time. Then any of those disinterested states will satisfy the subformula `interested => (eventually access)`. 
    
Why? Think about how an implication is satisfied. It can be satisfied if the right-hand side is true, but also if the left-hand side is false&mdash;in the case where no obligation needs to be incurred! So the implication above evaluates to _true_ in any state where the process isn't interested. And using `eventually` means _any_ single such state works...

</details>

---

It seems like we need a different temporal operator! What if we combine `always` and `eventually`? 

**Exercise:** Give it a try.

<details>
<summary>Think, then click!</summary>

We'll say: `always {interested => eventually access}`. Now, no matter what time it is, if the process is interested, it has to eventually get access. 
    
This sort of `always`-`eventually` pattern is good for (contingent) "infinitely often" properties, which is exactly what non-starvation is.

</details>

## Let's Try It Out!

I'm going to ask you to play the role of Forge. I've listed some temporal constraints below, and would like you to come up with some instances (lasso traces) that satisfy them. Don't use Forge unless you've already tried, and are stumped. 

For all examples, you may come up with your own shape of the world. That is, you might pick a University (where a state is a semester, with courses offered and taken) or your experience waiting for an elevator in the CIT, or anything else from your life! I'll use `A`, `B` and `C` to denote arbitrary facts that might be true, or not true---your job is to plug in specifics, and then find a satisfying trace!

I'll use a lot of parentheses, to avoid confusion about operator precedence...

**Exercise:** `eventually (always (A or B))`

<details>
<summary>Think, then click!</summary>

Suppose `A` stands for weekday, and `B` for weekend. Then the normal progression of time satisfies the constraint: after some point (perhaps right now) it will always be either a weekday or a weekend.

I am probably abstracting out some important details here, like the heat-death of the universe. But that's not really the point. The point is that alternation between `A` and `B` is allowed---it's always _either_ one or the other, or possibly even both.

</details>

---

**Exercise:** `always (eventually (X and (next_state Y)))`

<details>
<summary>Think, then click!</summary>

Suppose `A` stands for "Saturday", and `B` for "Sunday". Then it's always true that, at _any point_ in time, there is a Saturday-Sunday pair of days in the future. 
</details>

---

**Exercise:** `always ((eventually X) or (always Y)))`

<details>
<summary>Think, then click!</summary>

Suppose `A` stands for "final exam or demo", and `B` for "graduated". Then, at _any point_ in time, either there's a final in your future _or_ you've graduated (and stay graduated forever). 

Note that this doesn't mean you can't take a final exam after graduating if you want to. Both sides of the `or` can be true. It just means that, at any point, if you haven't graduated permanently, you must eventually take an exam.

</details>

---

## Non-Starvation in our Lock Model

A deadlock state is one where _no_ outgoing transitions are possible. How can we write a test in Temporal Forge that tries to find a reachable deadlock state? There are two challenges:

* How do we phrase the constraint, in terms of the transition predicates we have to work with? 
* How do we even allow Forge to find a deadlock, given that temporal mode *only* ever finds lasso traces? (A deadlock in a lasso trace is impossible, since a deadlock prevents progress!)

Let's solve the second challenge first, since it's more foundational.

### Finding Deadlocks Via Lassos

We could prevent this issue by allowing a `doNothing` transition from every state. Then from Forge's perspective there's no "deadlock", and a lasso trace can be found. We can add such a transition easily enough: 

```alloy
pred doNothing {
    flags' = flags
    loc' = loc
}
run {
    init
    always { 
        (some p: Process | {raise[p] or enter[p] or leave[p]})
        or doNothing 
    }
}
```

But we have to do so carefully, or the fix will cause new problems. If we allow a `doNothing` transition to happen _anywhere_, then Forge can find traces when nothing ever happens. In that case, our liveness property is definitely going to fail, even if we were modeling a smarter algorithm. So we need to reduce the power of `doNothing` somehow. 

Put another way: we started with an _overconstraint_ bug: if only lassos can be found, then we can't find a trace exhibiting deadlock. Adding a powerful `doNothing` fixes the overconstraint but adds a new _underconstraint_, because we'll get a lot of garbage traces where the system can just pause arbitrarily (while the trace continues).

We saw this phenomenon earlier when we were modeling [tic-tac-toe games](../ttt/ttt_games.md), and wanted to work around the fact that the `is linear` annotation forces exact bounds. We can use the same ideas in the fix here.

## Finding Deadlock

Let's look at one of our transitions:

```alloy
pred raise[p: Process] {
    // GUARD
    World.loc[p] = Disinterested
    // ACTION
    World.loc'[p] = Waiting
    World.flags' = World.flags + p
    all p2: Process - p | World.loc'[p2] = World.loc[p2]
}
```

Notice it's split into a "guard" and an "action". If all the constraints in the guard are true, the transition _can_ occur. Formally, we say that if all the guard constraints hold, then the transition is _enabled_. When should `doNothing` be enabled? When no other transition is. What if we made an "enabled" predicate for each of our other transitions? Then we could write: 

```alloy
pred doNothing {
    -- GUARD (nothing else can happen)
    not (some p: Process | enabledRaise[p]) 
    not (some p: Process | enabledEnter[p]) 
    not (some p: Process | enabledLeave[p]) 
    -- ACTION (no effect)
    flags' = flags
    loc' = loc
}
```

We won't create a separate `enabledDoNothing` predicate. But we will add `doNothing` to the set of possible moves:

```alloy
always { 
    (some p: Process | {raise[p] or enter[p] or leave[p]})
    or doNothing 
}
```

And we'd also better create those 3 `enabled` predicates, too. E.g., we might write:
```
pred raiseEnabled[t: Thread] {
    World.loc[t] = Uninterested 
}
```
which we would then use in the `raise` transition predicate.


Finally, we can write a check looking for deadlocks:

```alloy
test expect {
    noDeadlocks_counterexample: {
        -- setup conditions
        init
        always { 
            (some p: Process | {raise[p] or enter[p] or leave[p]})
            or doNothing 
        }
        -- violation of the property
        not always {
            some p: Process |
                enabledRaise[p] or
                enabledEnter[p] or
                enabledLeave[p] 
        }
    } is sat
}
```

which fails. Why? The counterexample (at least, the one I got) is 3 states long. And in the final state, both processes are `Waiting`. Success! Or, at least, success in **finding the deadlock**. But how should we fix the algorithm? And how can we avoid confusion like this in the future?
