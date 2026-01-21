# Liveness and Lassos

Let's return to thinking about our [mutual-exclusion](../relations/sets-induction-mutex.md) [model](../relations/sets-beyond-assertions.md). We had noticed that "every thread, whenever it becomes interested in the critical section, will eventually get access" is a different kind of property&mdash;one that requires an _infinite_ counterexample to disprove about the system. We called this sort of property a _liveness property_.

In a finite-state system, checking a liveness property amounts to looking for a bad cycle: some trace, starting from an initial state, that loops back on itself. Since these traces don't always loop back to the first state, we'll often call these _lasso traces_, named after a loop of rope. Here's an example. Consider the (reachable states only) transition system we drew last time:

![](https://i.imgur.com/EPMcgrl.png)

**Exercise:** Can you find a lasso trace that violates our liveness property?

<details>
<summary>Think, then click!</summary>
Here's one of them: 
    
* $(Un, 0, Un, 0)$; then
* $(Un, 0, W, 1)$; then
* $(Un, 0, C, 1)$; then back to
* $(Un, 0, Un, 0)$.
    
This lasso trace _does_ just happen to loop back to its first state. It shows the second process executing forever, and the first process remains uninterested forever. 

Is this good or bad? It depends on how we write the property, and what we mean when we write it. If we want to say that no process can _WAIT_ forever, then maybe this is OK. (Or is it?)
    
</details>

## Checking Liveness In Forge (Attempt 1)

How could we encode this sort of check in Forge? We wouldn't be able to use the inductive method&mdash;at least not in the same way&mdash;because we're looking for a bad cycle, not a bad state. So let's use the full finite-trace approach we used to generate games of Tic-Tac-Toe, but expand it to search for a bad _cycle_.

### Setting Up

We'll add the same finite-trace infrastructure as before. This time we're able to use full Forge, so we can use the transpose (`~`) operator to say that the initial state has no predecessors.

```alloy
one sig Trace {
    initialState: one State,
    nextState: pfunc State -> State
}

pred trace {
    no Trace.initialState.~(Trace.nextState)
    init[Trace.initialState]
    all s: State | some Trace.nextState[s] implies {
        delta[s, Trace.nextState[s]]
}
pred lasso {
    trace
    all s: State | some Trace.nextState[s]
}
```

Let's test our `lasso` predicate to make sure it's satisfiable. And, because we're careful, let's make sure it's _not_ satisfiable if we don't give the trace enough states to loop back on itself:

```alloy
test expect {
  lassoVacuity: { lasso } is sat
  lassoVacuityNotEnough: { lasso } for 2 State is unsat
}
```

### Beware...

There is actually a hidden overconstraint bug in our `lasso` predicate. It's not so extreme as to make the predicate unsatisfiable---so the test above passes! 

**Exercise:** What's the problem?

<details>
<summary>Think, then click!</summary>

We said that the initial state has no predecessor. This will prevent the lasso from looping back to the start&mdash;it must always have some states before the cycle begins. If the bug we're looking for always manifests as a loop back to the starting state, we would be **lulled into a false sense of success** by Forge, because it would fail to find the counterexample.

In fact, this would be a problem in the current model, since the counterexample we'd like to find does loop back to the original state.
    
</details>
</br>

**Watch out for this kind of bug!**

This is why thinking through vacuity testing is important. It's also a reason why, maybe, we'd like to avoid having to write all this temporal boilerplate (and potentially introduce bugs when we make a mistake).

### Identifying A Bad Cycle

If we know that the trace is a lasso, we can write a predicate that identifies some process being starved. This isn't easy, though. To see why, look at this initial attempt, which says that our property fails if `ProcessA` never enters the critical section:

```alloy
pred badLasso {
  lasso
  all s: State | s.loc[ProcessA] != InCS
}
test expect {
  checkNoStarvation: { badLasso } is unsat
}

```

This is _unsatisfiable_; the test passes. Could anything potentially be going wrong in our model, though?

We might first wonder, as we usually should, whether the test allocates enough states to reasonably find a counterexample. We've got 8 reachable states, so maybe we'd need 8 (or 9?) states in the test. That's true! There's something else wrong here, and it's more subtle. We'll need to address both of these problems to make progress. 

**Exercise:** What else is wrong?

<details>
<summary>Think, then click!</summary>

The `badLasso` predicate wouldn't hold true if the system allowed `ProcessA` to enter the critical section _once_ (and only once). We want `ProcessA` to be able to get access (eventually) whenever it needs that access. That is, we need to say that the _loop_ of the lasso contains no states where `ProcessA` is in the critical section, no matter what happens before the cycle starts.    
    
</details>
</br>

That sounds like a lot of work: we'd need to identify the sub-sequence of states representing the cycle and properly apply the constraint to only those states. More importantly, it sounds really easy to get this wrong if we write it ourselves, at this low level of abstraction, because the specifics might change as the model evolves. 

There's a better way. Forge has another language level&mdash;Temporal forge&mdash;that provides all of this automatically. 
