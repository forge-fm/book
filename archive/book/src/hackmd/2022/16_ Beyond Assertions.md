# 16: Beyond Assertions

###### tags: `Tag(sp22)`

## Logistics: Forge Update and Logging

The Forge update should be available! Please see the [notes from last time](https://hackmd.io/@lfs/BkT4rC3lq) re: logging and how to opt out, if you wish to opt out. 

I'm super happy with the curiosity-modeling submissions overall! 

Forge 3 goes out today. Forge 3 is a continuation of the garbage-collection lab; we ask you to model more advanced kinds of garbage collection that are actually able to collect unreachable memory, rather than just memory with a `0` reference count.

## Setting The Stage: States and Reachability

Recall the model from last time. We were modeling this simplified mutual-exclusion protocol: 

```
while(true) { 
     // [location: disinterested]
    this.flag = true;  // visible to other threads!
    //  [location: waiting]
    while(other.flag == true);    
    //  [location: in-cs] // "critical section"   
    this.flag = false;    
}
```

If there are 3 locations, and 2 flag values, then every thread has $3 \times 2 = 6$ possible states. If 2 threads are executing this loop, there are $6^2 = 6 \times 6 = 36$ possible states overall in the system. 

Our mutual exclusion property, which says that at most one process can be running the critical section at a time, is a statement that 4 specific states are unreachable: the 4 where both threads are in the critical-section location (with any possible combination of boolean flags).

That property wasn't "inductive": Forge could find transitions with a good prestate that end in one of those 4 bad states. So we enriched the invariant to say that it should _also_ hold that any thread in the waiting or critical-section locations must also have a raised flag. This prevented Forge from using many prestates it could use before: $(InCS, Waiting, 0, 0)$, for example. 

Today, we're going to do two things:
* build intuition for how the above actually worked; and
* talk about how we could approch verifying other, richer, kinds of property.

## Drawing The Picture

I really don't want to draw 36 states on the board, along with all their corresponding transition arcs. But maybe I don't need to. Let's agree that there are, in principle, 36 states, but just draw the part of the system that's reachable. 

Let's start with the initial state: $(Dis, Dis, 0, 0)$ and abbrieviate location tags to make writing them convenient for us: $Dis$ for "disinterested", $CS$ for "critical section", and $W$ for "waiting".

![](https://i.imgur.com/02KboGA.png)

Fill in the rest of the reachable states and transitions; don't add unreachable states at all. You should find the picture is significantly smaller than it would be if we had drawn _all_ states.

![](https://i.imgur.com/PQraiC7.png)

Keep going! In diagrams like this, where there are only 2 states, I like to split the state and draw the transition arcs for each process moving separately in different directions. (We're assuming, for now, that only one process moves at a time, even though they are executing concurrently.)

![](https://i.imgur.com/EPMcgrl.png)

I've marked the inability of a thread to make progress with an "**X**"; it's a transition that can't be taken.

## Other Properties

Just mutual exclusion isn't good enough! After all, a protocol that let _nobody_ into the critical section would guarantee mutual exclusion. We need at least one other property, one that might turn out to be more complex. We'll get there in 2 steps.

### Deadlock Freedom

If, at some point, _nobody_ can make progress, then surely the protocol isn't working. Both threads would be waiting forever, unable to ever actually get work done. 

A state where _no_ thread can transition is called a _deadlock state_. These are generally bad, and so verifying that a system is free of deadlocks is a common verification goal.

Does the system above satify deadlock-freedom? Can we check it using only the diagram we produced and our eyes?

<details>
No. The state $(W, W, 1, 1)$ is reachable, but has no exit transitions: neither thread can make progress. 
    
We can see that by doing a visual depth-first (or breadth-first) search of the sub-system for the reachable states.
</details>

This kind of verification problem is called _model checking_. Interestingly, there are other kinds of verification tools that use this graph-search approach, rather than the logic- and solver-based approach that Forge uses; you'll hear these tools referred to as _explicit-state model checkers_ and _symbolic model checkers_ respectively.

**Question:** How could we check for deadlocks using just the graph we drew and our eyes?

<details>
<summary>Think, then click!</summary>
In the same way we looked for a failure of mutual exclusion. We seek a reachable state with _no_ transitions out. 
    
In this case, we find such a state.
</details>

**Question:** How could we check for deadlock in Forge?

We could either try the inductive approach, or use the finite-trace method.

**Question:** Working from the graph you drew, how could we fix the problem?

We could add a transition from the deadlock state. Maybe we could allow the first thread to always take priority over the second:

![](https://i.imgur.com/gyt75Bk.png)

This might manifest in the code as an extra way to escape the `while` loop.

### Non-Starvation

Even if there are no deadlocks, it's still possible for one thread to be waiting forever. We'd prefer a system where it's impossible for one thread to be kept waiting while the other thread continues to completely hog the critical section.

This property is called _non-starvation_; more formally, it says that every thread must _always_ (at any point) _eventually_ (at some point) get access to the resource.

**Question:** How could we check non-starvation in this graph?

Not by looking for a single "bad state". That won't suffice...

### Safety Versus Liveness

It's worth noticing the differences between these 3 properties. In particular, consider what a _full counterexample trace_ to each must look like, if we were inclined to produce one. 
* For mutual-exclusion and deadlock-freedom, a counterexample trace could be finite. After some number of transitions, we'd reach a state where a deadlock or failure of mutual-exclusion has occurred. At that point, it's impossible for the system to recover; we've found an issue and the trace has served its purpose.
* For a failure of non-starvation, on the other hand, no finite trace can suffice. It's always possible that just ahead, the system will suddenly recover and prevent a thread from being starved. So here, we need some notion of an _infinite counterexample trace_ such that some thread never, ever, gets access.

The difference here is a fundamental distinction in verification. We call properties that have finite counterexamples _safety properties_, and properties with only infinite counterexamples _liveness properties_. 

#### Formal Definitions

There is a more formal definition that we'll discuss next week, but it's built on the above intuition.

People often describe safety properties as "something bad never happens" and liveness properties as "something good must happen". I don't like this wording, because it assumes an understanding of "goodness" and "badness". Instead, think about what the solver needs to do if it's seeking a counterexample trace. Then, one really is fundamentally different from the other.

Almost always, you'll find that a liveness property is more computationally complex to check. This doesn't mean that verifying liveness properties is always slower---just that one usually has to bring some additional tricks to bear on the algorithm.

In the context of a _finite_ state system, searching for an infinite counterexample amounts to looking for a reachable _cycle_ in the graph---not a single bad state.

