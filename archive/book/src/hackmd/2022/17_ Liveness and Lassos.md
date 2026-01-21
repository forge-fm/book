# 17: Liveness and Lassos

###### tags: `Tag(sp22)`

## Counterexamples To Liveness

Last time we noticed that "every thread, whenever it becomes interested in the critical section, will eventually get access" is a different kind of property---one that requires an _infinite_ counterexample to disprove about the system. We called this sort of property a _liveness property_.

In a finite-state system, checking a liveness property amounts to looking for a bad cycle: some trace, starting from an initial state, that loops back on itself. Since these traces don't always loop back to the first state, we'll often call these _lasso traces_, named after a loop of rope.

Here's an example. Consider the (reachable states only) transition system we drew last time:

![](https://i.imgur.com/EPMcgrl.png)

Can you find a lasso trace that violates our liveness property?

<details>
<summary>Think, then click!</summary>
Here's one of them: 
    
* $(Dis, 0, Dis, 0)$; then
* $(Dis, 0, W, 1)$; then
* $(Dis, 0, C, 1)$; then back to
* $(Dis, 0, Dis, 0)$.
    
This lasso trace _does_ just happen to loop back to its first state. It shows the second process executing forever, and the first process being forced to wait eternally.
    
</details>

## Checking Liveness In Forge (Attempt 1)

How could we encode this sort of check in Forge? We wouldn't be able to use the inductive method---at least, not without a lot of careful theoretical work! So let's use the finite-trace approach we used to generate games of Tic-Tac-Toe. But we can't just say that _some state_ in a trace violates the property: we need to encode the search for a bad cycle. 

### Setting Up

We'll add the same finite-trace infrastructure as before. This time we're able to use full Forge, so we'll use the transpose (`~`) operator to say that the initial state has no predecessors.

```alloy
one sig Trace {
    initialState: one State,
    nextState: pfunc State -> State
}

pred trace {
    no Trace.initialState.~(Trace.nextState)
    init[Trace.initialState]
    all s: State | some Trace.nextState[s] implies {
        trans[s, Trace.nextState[s]]
    }
}
```

### Enforcing Lasso Traces

It's helpful to have a helper predicate that enforces the trace being found is a lasso.

```alloy
pred lasso {
    trace
    all s: State | some Trace.nextState[s]
}
```

Let's test this predicate to make sure it's satisfiable. And, because we're careful, let's make sure it's _not_ satisfiable if we don't give the trace enough states to loop back on itself:

```alloy
test expect {
  lassoVacuity: { lasso } is sat
  lassoVacuityNotEnough: { lasso } for 2 State is unsat
}
```

### Beware...

There is actually a hidden overconstraint bug in our `lasso` predicate. It's not so extreme as to make the predicate unsatisfiable---so the test above passes! What's the problem?

<details>
<summary>Think, then click!</summary>
We said that the initial state has no predecessor. This will prevent the lasso from looping back to the start---it will always have some states before the cycle begins. As a result, the counterexample trace we were thinking about just wouldn't appear! We would be **lulled into a false sense of success** by Forge, because the very counterexample we need to see is excluded by the bug.
</details>

This is why thinking through vacuity testing is important. It's also a reason why, maybe, we'd like to avoid having to write all this temporal boilerplate (and potentially introduce bugs).

### Identifying A Bad Cycle

If we know that the trace is a lasso, we can write a predicate that identifies some process being starved. This isn't trivial, though. To see why, look at this initial attempt:

```alloy
pred badLasso {
  lasso
  all s: State | s.loc[ProcessA] != InCS
}
test expect {
  checkNoStarvation: {
      badLasso
  } is unsat
}
```

This test _fails_, which is what we'd expect. So what's wrong with it?

We might first wonder, as we usually should, whether the test allocates enough states to reasonably find a counterexample. We've got 8 reachable states, so maybe we'd need 8 (or 9?) states in the test. But there's something more subtle wrong here. 

<details>
<summary>Think, then click!</summary>
The `badLasso` predicate wouldn't hold true if the system allowed `ProcessA` to enter the critical section _once_ (and only once). We need to say that the _loop_ of the lasso doesn't allow a process in, no matter what happens before the cycle starts.    
    
</details>

That sounds like a lot of work. More importantly, it sounds really easy to get wrong. Maybe there's a better way.

## Temporal Operators

I wonder if we could add notions of "always" and "eventually" and so on to Forge?

Your class exercise today is to try out [this survey](https://forms.gle/RWh9Tn68YC4CUYLU6).

In contrast to the last survey, we're not asking you whether some set of constraints should be satisfiable or unsatisfiable. Rather, we're asking whether a _specific trace_ satisfies a constraint that uses the new operators.

### Note For Lab

Because of my illness last week and the snow day, we're around half a class behind versus the original plan. This means that this week's lab will be the first some of you see of Forge's temporal mode---which introduces all the operators in the survey! 

Here's a quick run-down:
* lasso traces are kind of a bother to handle manually; 
* properties like the ones we checked in this example are more naturally expressed with (carefully defined) operators; and
* supporting more industrial model-checking languages in Forge will give everyone a better grounding in using those tools in the future (outside of class, but also on the term project).

Forge's temporal mode takes away the need for you to explicitly model traces. It forces the engine to only ever find lasso traces, and gives you some convenient syntax for working under that assumption. A field can be declared `var`, meaning it may change over time. And so on. 

I'll repeat the most important clause above: Forge's temporal mode **forces the engine to only ever find lasso traces**. It's very convenient if that's what you want, but don't use it if you don't!

Here's an example of what I mean. Suppose we're modeling a system with a single integer counter...

```
#lang forge

option problem_type temporal
option max_tracelength 10

one sig Counter {
  var counter: one Int
}

run {
  -- The counter starts out at 0
  Counter.counter = 0
  -- The counter is incremented every transition:
  always Counter.counter' = add[State.counter, 1]
} for 3 Int
```

This is _satisfiable_, but only by exploiting integer overflow. If we weren't able to use overflow, this would be _unsatisfiable_: there wouldn't be enough integers available to form a lasso. And temporal mode **only looks for lassos**.


