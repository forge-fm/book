# 22: Deadlocks and Lassos, Fairness

###### tags: `Tag(sp22)`

**Update to Forge 1.5.0. Especially if you're a Windows user.**

**Don't forget: next Wednesday, we have a guest lecture.**

Please turn on your camera for hours if you can.

We last stopped work on our locking-algorithm example when we realized it had a deadlock bug. Today we'll:
* actually encode the search for a deadlock in temporal mode;
* fix the deadlock by slightly changing the algorithm; and
* learn about the need for a _precondition_ provided by the scheduler.

## Finding Deadlock

We noticed last time that, since temporal mode only finds lasso traces, deadlock states can never appear in any trace found. So we decided to add a `doNothing` transition---in a limited way! The question is, what's the limitation?

Let's look at one of our transitions:

```alloy
pred raise[p: Process] {
    World.loc[p] = Disinterested
    World.loc'[p] = Waiting
    World.flags' = World.flags + p
    all p2: Process - p | World.loc'[p2] = World.loc[p2]
}
```

Notice it's split (implictly) into a "guard" and an "action". If all the constraints in the guard are true, the transition _can_ occur. Formally, we say that if all the guard constraints hold, then the transition is _enabled_. When should `doNothing` be enabled? When no other transition is.

```alloy
pred doNothing {
    -- GUARD (nothing else can happen)
    not (some p: Process | enabledRaise[p]) 
    not (some p: Process | enabledEnter[p]) 
    not (some p: Process | enabledLeave[p]) 
    -- ACTION
    flags' = flags
    loc' = loc
}
```

We won't create a separate `enabledDoNothing` predicate. But we will add `doNothing` to the set of possible moves:

```alloy
pred trans {
    some p: Process | 
        raise[p] or
        enter[p] or 
        leave[p] or 
        doNothing 
}
```

And we'd also better create those 3 `enabled` predicates, too.

Finally, we can write a check looking for deadlocks:

```alloy
test expect {
    noDeadlocks: {
        lasso implies
        always {
            some p: Process |
                enabledRaise[p] or
                enabledEnter[p] or
                enabledLeave[p] 
        }
    } is checked
}
```

which fails. Note that when it does, the new version of Forge prints a somewhat-understandable representation of the counterexample, with metadata:

```
Instance found, with statistics and metadata:
(Sat
 '(#hash((Disinterested . ((Disinterested0)))
         (InCS . ((InCS0)))
         (Location . ((Disinterested0) (Waiting0) (InCS0)))
         (Process . ((ProcessA0) (ProcessB0)))
         (ProcessA . ((ProcessA0)))
         (ProcessB . ((ProcessB0)))
         (Waiting . ((Waiting0)))
         (World . ((World0)))
         (flags . ())
         (loc
          .
          ((World0 ProcessA0 Disinterested0)
           (World0 ProcessB0 Disinterested0))))
   #hash((Disinterested . ((Disinterested0)))
         (InCS . ((InCS0)))
         (Location . ((Disinterested0) (Waiting0) (InCS0)))
         (Process . ((ProcessA0) (ProcessB0)))
         (ProcessA . ((ProcessA0)))
         (ProcessB . ((ProcessB0)))
         (Waiting . ((Waiting0)))
         (World . ((World0)))
         (flags . ((World0 ProcessA0)))
         (loc
          .
          ((World0 ProcessA0 Waiting0) (World0 ProcessB0 Disinterested0))))
   #hash((Disinterested . ((Disinterested0)))
         (InCS . ((InCS0)))
         (Location . ((Disinterested0) (Waiting0) (InCS0)))
         (Process . ((ProcessA0) (ProcessB0)))
         (ProcessA . ((ProcessA0)))
         (ProcessB . ((ProcessB0)))
         (Waiting . ((Waiting0)))
         (World . ((World0)))
         (flags . ((World0 ProcessA0) (World0 ProcessB0)))
         (loc . ((World0 ProcessA0 Waiting0) (World0 ProcessB0 Waiting0)))))
 '((size-variables 2891)
   (size-clauses 5891)
   (size-primary 141)
   (time-translation 135)
   (time-solving 12)
   (time-building 61))
 '((prefixLength 3) (loop 2)))
Theorem noDeadlock failed.
```

We could rephrase the test as a `run` to visualize this in Sterling. (I'd like to make this happen automatically soon.) But already we see the counterexample is 3 states long---every state consists of a hash (dictionary). And in the final state, both processes are `Waiting`. Success! Or, at least, success in finding the deadlock.

## Fixing Deadlock

Our little algorithm is 90% of the way to the the [Peterson lock](https://en.wikipedia.org/wiki/Peterson%27s_algorithm).  The Peterson lock just adds one extra bit of state, and one transition to set that bit. In short, if our current algorithm is analogous to raising hands for access, the other bit added is like a "no, you first" when two people are trying to get through the door at the same time. (Conveniently, that's exactly the sort of situation our both-flags-raised deadlock represented.)

We'll add a `polite: lone Process` field to each `Process`, to represent which process (if any) has just said "no, you go first". The algorithm now needs a step to set this value. It goes something like this (in pseudocode) after the process becomes interested:

```
    my flag = true
    polite = me
    while (other flag == true && polite == me);
    // enter critical section                      
    my flag = false
```         
         
So we just need one more location, which I'll call `Halfway`, and corresponding edits. One new transition:

```alloy
pred enabledNoYou[p: Process] {
    World.loc[p] = Halfway
}
pred noYou[p: Process] {
    enabledNoYou[p]
    World.loc'[p] = Waiting
    World.flags' = World.flags
    World.polite' = p
    all p2: Process - p | World.loc'[p2] = World.loc[p2]

```

one small edit in `raise`, to set 

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

Then we add the new transition to the overall transition predicate, to `doNothing`, to the deadlock check test---anywhere we previously enumerated possible transitions.

We also need to expand the frame conditions of all other transitions to keep `polite` constant.

**Advice:** Beware of forgetting (or accidentally including) primes. This can lead to unsatisfiable results, since the constraints won't do what you expect between states.

#### Trace Length

Traces are getting pretty long; lets make sure to increase the maximum trace length with ```option max_tracelength 10``` (the default is 5).

### Let's Check Non-Starvation

```alloy
noStarvation: {
        lasso implies {
        all p: Process | {
            always {
                -- beware saying "p in World.flags"; using loc is safer
                --   (see why after fix disinterest issue)                
                p in World.flags =>
                eventually World.loc[p] = InCS
            }
        }}
    } is checked
```

This passes. Yay!

## Abstraction Choices We Made

We made a choice to model processes as always eventually _interested_ in accessing the critical section. There's no option to become disinterested, or to pass on a given cycle. 

Suppose we allowed processes to become disinterested and go to sleep. How could this affect the correctness of our algorithm, or of the non-starvation property? 

<details>
<summary>Think, then click!</summary>
The property might break because a process's flag is still raised as it is _leaving_ the critical section, so the implication is too strong. It might be safer to say `World.loc[p] = Waiting => ...`. 
    
But even the correct property will fail in this case: there's nothing that says one process can't completely dominate the overall system, locking its counterpart out. Suppose that `ProcessA` is `Waiting` and then `ProcessB` stops being interested. _If we modeled disinterest as a while loop_, perhaps using `doNothing` or a custom `stillDisinterested` transition, then `ProcessA` could follow that loop forever, leaving `ProcessB` enabled, but frozen.
</details>
<br/>

#### Aside

In your next homework, you'll be _critiquing_ a set of properties and algorithms for managing an elevator. Channel your annoyance at the CIT elevators, here! Of course, none of our models encompass the complexity of the CIT elevators...

## Fairness

In a real system, it's not really up to the process itself whether it gets to run forever; it's up to the operating system's scheduler. Thus, "fairness" in this context isn't so much a property to guarantee as a **precondition to require**. Without the scheduler being at least _somewhat_ fair, the algorithm can do nothing.

Think of a precondition as an environmental assumption, that we rely on when checking the algorithm. This is a common sort of thing in verification and, for that matter, in computer science. If you take a cryptography course, you might encounter the phrase "...is correct, subject to standard cryptographic assumptions". 

Let's add the precondition, which we'll call "fairness". There are many ways to phrasing fairness, and since we're making it an assumption about the world outside our algorithm, we'd really like to pick something that suffices for our needs, but isn't any stronger than that. 

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

This is initially a little strange. There are a few ways to express fairness (weak, strong, ...)
but weak fairness can often be less expensive---and at any rate, is sufficient for our needs! Here we say that if a process is ready to go with some transition forever (possibly a different transition per state), it must be allowed to proceed (with some transition, possibly different each time) infinitely often.

Hillel Wayne has a [great blog post](https://www.hillelwayne.com/post/fairness/) on the differences between these. Unfortunately it's in a different modeling language, but the ideas come across well. 

Once we add `weakFairness` as an assumption, the properties pass. 
