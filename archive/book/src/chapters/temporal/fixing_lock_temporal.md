# Peterson Lock and Fairness

Let's finally _fix_ [the broken locking algorithm](../relations/sets-induction-mutex.md) [we modeled before](../relations/sets-beyond-assertions.md). We [decided](./liveness_and_lassos.md) that it would be a bother to encode lasso traces manually in Relational Forge, but it seems like Temporal Forge might give us exactly what we need.

The final version of the model will be in [peterson.frg](./peterson.frg).

## Fixing Deadlock

Our little algorithm is 90% of the way to a _working_ mutex called the [Peterson lock](https://en.wikipedia.org/wiki/Peterson%27s_algorithm).  The Peterson lock just adds one extra bit of state, and one transition to set that bit. In short, if our current algorithm is analogous to raising hands for access, the other bit added is like a "no, you first" when two people are trying to get through the door at the same time; that's exactly the sort of situation our both-flags-raised deadlock represented.

**TODO: add transition diagram here, and probably for lock1**

To represent which process (if any) has most recently said "no, you go first", we'll add a `polite: lone Process` field to each `Process`. The algorithm now needs to take a step to set this value. It goes something like this (in pseudocode) after the process becomes interested:

```
// location: uninterested 
this.flag = true
// location: halfway   (NEW)
polite = me         
// location: waiting 
while(other.flag == true || polite == me) {} // hold until their flag is lowered _or_ the other is being polite
// location: in CS 
run_critical_section_code(); // don't care details
this.flag = false
```         

Because we're modeling individual operations executing, we'll need to add a new location to the state, which I'll call `Halfway`. We'll also need a new transition (and to change existing transitions in some places). The new transition might look something like this:

```alloy
pred enabledNoYou[p: Process] {
    World.loc[p] = Halfway
}
pred noYou[p: Process] {
    -- GUARD
    enabledNoYou[p]
    -- ACTION
    World.loc'[p] = Waiting
    World.flags' = World.flags
    World.polite' = p
    all p2: Process - p | World.loc'[p2] = World.loc[p2]
}
```

We'll need a small edit in `raise`, to set 

```
World.loc'[p] = Halfway
```
instead of 
```
World.loc'[p] = Waiting
```

and a modification to the `enter` transition so that it's enabled if _either_ nobody else has their flag raised _or_ the current process isn't the one being polite anymore:

```alloy
pred enabledEnter[p: Process] {
    World.loc[p] = Waiting 
    -- no other processes have their flag raised *OR* this process isn't the polite one
    (World.flags in p or World.polite != p)
}
```

Then we add the new transition to the overall transition predicate, to `doNothing`, to the deadlock check test&mdash;anywhere we previously enumerated possible transitions.

We also need to expand the frame conditions of all other transitions to keep `polite` constant if we aren't explicitly modifying it.

~~~admonish warning title="Watch out!" 
Beware of forgetting (or accidentally including) primes. This can lead to unsatisfiable results, since the constraints won't do what you expect between states. E.g., an accidental double-prime will mean "in the state _after_ next".
~~~

### Let's Check Non-Starvation

```alloy
noStarvation: {
    lasso implies {
        all p: Process | {
            always {
                -- Beware saying "p in World.flags". Why? Read on...
                p in World.flags =>
                eventually World.loc[p] = InCS
            }
        }
    }
} is checked
```

This passes. Yay!

~~~admonish tip title="Should we be suspicious?"
That was really easy. Everything seems to be working perfectly. Maybe we can stop early and go get ice cream. 

But we should probably do some validation to make sure we haven't missed something. Here's a question: *is our domain model realistic enough to trust these results?*
~~~

## Abstraction Choices We Made

We made a choice to model processes as always eventually _interested_ in accessing the critical section. There's no option to remain uninterested, or even to terminate (as many processes do in real life). Suppose we allowed processes to become uninterested and go to sleep. How could this affect the correctness of our algorithm, or threaten our ability to verify the non-starvation property with the current model? 

<details>
<summary>Think, then click!</summary>
    
The property might break because a process's flag is still raised as it is _leaving_ the critical section, even if it never actually wants access again. So the implication is too strong. It is more correct to say `World.loc[p] = Waiting => ...` than `p in World.flags`, which is why we use it in the above. 
    
But even the correct property will fail in this case: there's nothing that says one process can't completely dominate the overall system, locking its counterpart out. Suppose that `ProcessA` is `Waiting` and then `ProcessB` stops being interested. _If we modeled disinterest as a while loop_, perhaps using `doNothing` or a custom `stillDisinterested` transition, then `ProcessA` could follow that loop forever, leaving `ProcessB` enabled, but frozen, because our model only lets one process transition at a time.
</details>

Let's deal with that second problem now.

<!-- In your next homework, you'll be _critiquing_ a set of properties and algorithms for managing an elevator. Channel your annoyance at the CIT elevators, here! Of course, none of our models encompass the complexity of the CIT elevators... -->

## Fairness

In the real world, it's not just the process itself that says whether or not it runs forever; it's also up to the operating system's scheduler, the system's hardware, etc. Thus, non-starvation is contingent on some **preconditions** that the domain must provide. 
Without the scheduler being at least _somewhat_ fair, even the best algorithm can guarantee very little. 

Let's add the precondition, which we'll call "fairness". Again, keep in mind that, in this context, fairness is _not a property our locking system must guarantee_. Rather, it's something our locking system needs from its environment. This is a common thing to see in verification and, for that matter, in all of computer science. To underscore this point, you might review the [binary search tree](../bst/bst.md) invariant. Is the BST invariant a properties for the search to guarantee, or a precondition for its correctness? Of course, the status of a given property can shift depending on our perspective: if we're modeling the algorithm to _add_ to the binary search tree, preserving the invariant is now very important.

~~~admonish note title="Other precondition examples"
Is Dijkstra's algorithm always correct, on any weighted directed graph? Is RSA encryption absolutely secure, no matter how powerful or how lucky the adversary is?
~~~

### Expressing Fairness

There are many ways to phrasing fairness, and since we're making it an assumption about the world outside our algorithm, we'd really like to pick something that suffices for our needs, but _isn't any stronger than that._ Once we add the `weakFairness` predicate below as an assumption, the properties pass. 

```alloy
pred weakFairness {
    all p: Process | {
        (eventually always 
                (enabledRaise[p] or
                enabledEnter[p] or
                enabledLeave[p] or
                enabledNoYou[p])) 
        => 
        (always eventually (enter[p] or raise[p] or leave[p] or noYou[p]))        
    }
}
```

This may initially look a little strange. It still looks rather strange to me, years after learning it. It just happens that there are multiple ways to express fairness. Hillel Wayne has a [great blog post](https://www.hillelwayne.com/post/fairness/) on the differences between them. (Unfortunately it's in a different modeling language, but the ideas come across well.) Regardless, "weak" fairness is sufficient for our needs! It says that if a process remains ready to move forward forever (possibly via a different transition per state), it must be allowed to proceed infinitely often.



