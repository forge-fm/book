# 10: Counterexamples To Induction

###### tags: `Tag(sp22)`

* Please remember your anonymous IDs on assignments! (This helps us respect your anonymity while also letting us detect potential errors and ways to fix Forge. No ID = no data. Real ID = no anonymity.) I'm starting to use a fake anonymous ID in class (e.g., `#lang forge/bsl "lecture_example" "tim_nelson@brown.edu"`).
* We'll be sending around a new form to link "new" anon IDs if you needed to switch.
* Curiosity modeling signups are going out soon. Read over others ideas! I'm trying to reply as I can, but apologies if I don't get to you. Look for answers to similar ideas. 
* The `dev` branch of Forge has a number of fixes (including evaluator disabled on old instances, some better errors in example blocks).
* Friday will contain a longer in-class exercise. Please be prepared. 

## Forge Reminders

* Beware `one`. It's very convenient but dangerous. If you write `one a1, a2: Animal | ...` but the `...` is symmetric (that is, it doesn't care about which is `a1` and which is `a2`), then the entire constraint can't be satisfied except under very limited conditions---the assignment to the variables is _not_ unique!
* Remember that instance blocks exactly define the value of every field and the objects in every sig. Only define a field once, use only a sig or field name on the left-hand side, and if you use sig names on the right-hand side, remember to define those sigs _beforehand_. 

## Induction

When we're talking about whether or not a reachable state violates a desirable property $P$ (recall we sometimes say that if this holds, $P$ is an _invariant_ of the system), it's useful to think geometrically. Here's a picture of the space of _all states_, with the cluster of "good" states separated from the "bad":

![](https://i.imgur.com/n3F16P4.png)

If this space is large, we probably can't use trace-finding to get a real _proof_: we'd have to either reduce the trace length (in which case, maybe there's a bad state _just barely_ out of reach of that length) or we'd be waiting until the sun expands and engulfs the earth.

Traces are still useful, especially for finding shallow bugs, and the technique is used in industry! But we need more than one tool in our bag of tricks. 

### Step 1: Initiation or Base Case

Let's break the problem down. What if we just consider reachability for traces of length $0$---that is, traces of only one state, an `initial` state?

This we can check in Forge just by asking for a state `s` satisfying `{initial[s] and wellformed[s] and not P[s]}.` There's no exponential blowup with trace length since the transition predicates are never even involved! If we see something like this:

![](https://i.imgur.com/Aia9V0q.png)

We know that at least the starting states are good. If instead there was a region of the starting states that overlapped the bad states, then we immediately know that the property isn't invariant.

### Step 1.5: Noticing and Wondering

We can surely also check whether there are bad states within $1$ transition. We're using the transition predicate (or predicates) now, but only _once_. Forge can also do this; we ask for a pair of states `s0`, `s1` satisfying `{initial[s0] and someTransition[s0, s1] and not P[s1]}` (where `someTransition` is my shorthand for allowing any transition predicate to work; we could write the predicate ourselves). 

If Forge doesn't find any way for the second state to violate $P$, it means we have a picture like this:

![](https://i.imgur.com/NdA7RwF.png)

It's looking promising! Note that in general, there might be overlap (as shown) between the set of possible initial states and the set of possible second states. (For example, imagine if we allowed a `doNothing` transition at any time).

If we keep following this process exactly, we'll arrive back at the trace-based approach: a set of 3rd states, a set of 4th states, and so on. 

Sometimes great ideas arise from dire limitations. What if we limit ourselves to only ever asking Forge for these _two state_ examples? That would solve the exponential-blowup problem of traces, but how can we ever get something useful, that is, a result that isn't limited to trace length 1?

I claim that we can use these small, efficient queries to often show that $P$ holds at _any_ finite length from a starting state. But how? 

By no longer caring whether the pre-state of the check is reachable or not. 

### Step 2: Consecution or Inductive Case

We'll ask Forge whether `{P[s0] and someTransition[s0, s1] and not P[s1]}` is satisfiable for _any_ pair of states. Just so long as the pre-state satisfies $P$ and the post-state doesn't. We're asking Forge if it can find a transition that looks like this:

![](https://i.imgur.com/CWSjSrr.png)

If the answer is _no_, then it is simply impossible for any transition predicate to stop property $P$ from holding: if it holds in the pre-state, it _must_ hold in the post-state. Always.

But if that's true, and we know that all initial states satisfy $P$, then all states reachable in $1$ transition satisfy $P$ (by what we just checked). And if that's true, then all states reachable in $2$ transitions satisfy $P$ also (since all potential pre-states must satisfy $P$). And so on: _any_ state that's reachable in a finite number of transitions must satisfy $P$. 

If you've seen "proof by induction" before in another class, we've just applied the same idea here. Except, rather than using it to show that the sum of the numbers from $1$ to $n$ is $\frac{k(k+1)}{2}$, we've just used it to prove that $P$ is invariant in our system. 

In Tic-Tac-Toe, this would be something like "cheating states can't be reached with legal moves". In an operating system, this might be "two processes can never modify a block of memory simultaneously". In hardware, it might be "only one device has access to write to the bus at any point". 

For most computer-scientists, I think that this feels like a far more relatable and immediately useful example of the induction principle. That's not to dismiss mathematical induction! I quite like it (and it's useful for establishing some useful results related to Forge). But multiple perspectives enrich life.

What if Forge _does_ find a transition like this? Does it mean that $P$ is not an invariant of the system?

<details>
<summary>Think, then click!</summary>
No! It just means that $P$ isn't _inductively invariant_.  The pre-state that Forge finds might not _itself_ be reachable!
    
This technique is a great way to quickly show that $P$ is invariant, but if it fails, we need to do more work.
</details>

### Enriching the Invariant 

The solution to this problem is called "enriching the invariant". More on this next week.

### How To Do It

```alloy
test expect {
    base: {
      some s: State | starting[s] and cheating[s]
    } for 1 State, 2 Player, 3 Int is unsat
    inductive: {
      some disj pre, post: State | 
      some row, col: Int, p: Player | {       
        move[pre, row, col, p, post]
        not cheating[pre]
        cheating[post]
      }
  } for 2 State, 2 Player, 3 Int is unsat
```

As written, the second test will take a very long time (around 3 minutes on my laptop). Why? Is there some sort of hint we could provide helpfully to Forge?

<details>
<summary>Think, then click!</summary>
We could tell Forge that `wellformed` holds. This is a nearly-2-orders-of-magnitude speedup for me. If you're wondering why, consider what information `wellformed` provides.
</details>

### Also...

I forgot to allow `doNothing` in the above code! But it doesn't matter. I made a mistake in lecture: the pre-state I gave is something like:

```
Prestate: 
X O
X O
X O
```

But `doNothing` can't change it! So this property is indeed inductive, and the mistake was mine. (Really, I ought to have run it in Forge, rather than my imagination!)

## But Can We Trust The Model?

What would it mean for this verification idea if there were simply no initial states, or no way to take a certain transition? That would probably be a bug in the model; how would it impact our proof?

Look again at the two checks we wrote. If `initial` were unsatisfiable by any state, surely the Step 1 check would also be unsatisfiable (since it just adds _more_ constraints). Similarly, unsatisfiable transition predicates would limit the power of Step 2 to find ways that the system could transition out of safety. This  would mean that our confidence in the check was premature: Forge would find no initial bad states, _but only because we narrowed its search to nothing_! 

This problem is called _vacuity_, and I'll give you another example. Suppose I told you: "All my billionaire friends love Logic for Systems". I have, as far as I know anyway, no billionaire friends. So is the sentence true or false? If you asked Forge, it would say that the sentence was true---after all, there's no billionaire friend of mine who _doesn't_ love Logic for Systems...

This is a problem you might hear about in other courses like 0220, or in the philosophy department. And so there's a risk you'll think vacuity is silly, or possibly a topic for debate among people who like drawing their As upside down and their Es backwards, and love writing formulas with lots of Greek letters in. **Don't be fooled!** Vacuity is a major problem even in industrial settings like Intel, because verification tools are literal-minded. (Still doubtful? Ask Tim to send you links.)

At the very least, we'd better test that `wellformed` can be satisfied:

```alloy
test expect {
  vacuity_wellformed: {wellformed} is sat
}
```

This isn't a guarantee of trustworthiness, but it's a start. And it's easy to check with Forge. 
