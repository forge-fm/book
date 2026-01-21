# 8: More Questions, More Traces

###### tags: `Tag(sp22)`

* One more day for Forge 1. 
* We're offsetting Forge 2 by a day (so you don't "lose" a day).
* First case study out soon. You'll be working on it for 3 weeks in total; we've spread it out into weekly milestones so that it won't be overwhelming. You'll have Forge homework while it's out, but they should complement each other well (in content and in workload).
* No lab next week! We want you to spend the time experimenting with the case study model.

There's no exercise again today; I wanted to maximize question coverage. I expect to have one on Monday.

## Answering (More) Questions

Before we turn to Tic-Tac-Toe, I'll touch on 2 points from Forge 1. First, something that come up on Ed, and then a **very important technique** in answer to a question about debugging.

### An Interesting Use Of Reachable

I was surprised and incredibly proud to see some of you using `reachable` in a way I didn't anticipate. When I solved Forge 1, I said that an element is reachable like this:

```alloy
reachable[ele, st.top, next]
```

The trouble with that is, since `reachable` enforces **one or more** hops, this will say that the top of the stack isn't reachable in that state. So we have to add something like `or ele = st.top`. Some of you came up with this:

```alloy
reachable[ele, st, next, top]
```

I never expected this solution! The examples I gave used `reachable` in examples that only had a single type in the path being found. Family trees, for instance, still only involved `Person` even though there were two `parent` fields that could be used. 

Can we check whether this works? Yes! In fact, let's use the predicate-comparison technique from last time.

```alloy
-- NOT THE EXACT STENCIL, BEWARE!
sig Element {
    next: lone Element
}
sig State {
    top: lone Element
}

test expect {
    offLabelReachableUnguarded: {
        some s: State, e: Element | 
            not (reachable[e, s, next, top] iff 
                 reachable[e, s.top, next])
    } is sat

    offLabelReachableGuarded: {
        all s: State, e: StackElement | 
           reachable[e, s, next, top] iff 
           (reachable[e, s.top, next] or e = s.top)
    } is checked
}
```

The `theorem` just means that the negation is unsatisfiable---Forge provides this as "syntactic sugar". I could have just added the `not` and said `is unsat`.

Anyway, nice job!

### Dealing With Unsatisfiability

Many of you have had your first encounter with an over-constraint bug this week. Maybe you wrote an `is sat` test and it seemed to never stop. Maybe you wrote a `run` command and Sterling just produced an `UNSAT0` result. 

Getting back an unsat result can take a long time. Why? Think of the search process. If there is a satisfying instance, the solver can find it early. If there isn't, the solver needs to explore the entire space of possibilities. Yeah, there are smart algorithms for this, and it's not *really* enumerating the entire space of instances, but the general idea holds. 

So if you run Forge and it doesn't seem to ever terminate, it's not necessary a Forge problem---surprising over-constraint bugs can produce this behavior.

So, how do you debug a problem like this? The first thing I like to do is reduce the bounds (if possible) and, if I still get unsat, I'll use that smaller, faster run to debug. But at that point, we're kind of stuck. `UNSAT0` isn't very helpful. 

Today I want to show you a very useful technique for discovering the problem. There are more advanced approaches we'll get to later in the course, but for now this one should serve you well. 

The core idea is: encode an instance you'd expect to see as a set of constraints, run _those_ constraints only, and then use the evaluator to explore why it fails your other constraints. Let's do an example!

```alloy
#lang forge/bsl
-- NOT THE EXACT STENCIL!
sig State {
  top: lone Element
}
sig Element {
  next: lone Element             
}

pred buggy {
  all s: State | all e: Element {
    s.top = e or reachable[e, s.top, next]
  }
  some st1, st2: State | st1.top != st2.top     
  all e: Element | not reachable[e, e, next]
}
test expect {
  exampleDebug: {buggy} is sat
}
```

This test fails. But why?

```alloy
run {
  some st1, st2: State |
  some ele1, ele2: Element | {
    st1.top = ele1
    st2.top = ele2
    ele1.next = ele2   
    no ele2.next    
  }
} for exactly 2 State, exactly 2 Element
```

Given this instance, the question is: **why didn't Forge accept it?** There must be some constraint, or constraints, that it violates. Let's find out which one. We'll paste them into the evaluator...
* `some st1, st2: State | st1.top != st2.top`? This evaluates to `#t` (true). No problem there.
* `  all s: State | all e: Element {
    s.top = e or reachable[e, s.top, next]
  }`? This evaluates to `#f` (false). So this is a problem.
  
Now we proceed by breaking down the constraint. The outer shell is an `all`, so let's plug in a concrete value:
*  `all e: Element {
    State0.top = e or reachable[e, State0.top, next]
  }`? This evaluates to `#f`. So the constraint fails for `State0`. 
  
**Important**: Don't try to name specific states in your model. They _don't exist_ at that point. 

Which element does the constraint fail on? Again, we'll substitute concrete values and experiment:
*  `State0.top = Element0 or reachable[Element0, State0.top, next]`? This evaluates to `#t`. What about `State0.top = Element1 or reachable[Element1, State0.top, next]`?

Following this process very often leads to discovering an over-constraint bug, or a misconception the author had about the goals of the model or the meaning of the constraints. 

**Question: What's the problem here?**

<details>
<summary>Think, then click!</summary>
Since the `next` field never changes with time, the `all` constraint doesn't allow states to vary the `top` of the stack. Instead, we need a weaker constraint to enforce that the stack is shaped like a state.
</details>

## Doing Nothing (Productively)

Continuing from last time, we'd just realized that with `exactly 10 State`, we couldn't ever produce a trace that won the game early. The fix for this is to allow the model some flexibility---but not too much!

Let's add an additional transition that does nothing. We can't "do nothing" in the predicate body, though -- that would just mean _anything_ could happen. What we mean to say is that the state of the board remains the same, even if the before and after `State` objects differ.

```alloy
pred doNothing[pre: State, post: State] {
    pre.board = post.board
}
```

We also need to edit the `traces` predicate to allow `doNothing` to take place:

```alloy
pred traces {
    -- The trace starts with an initial state
    starting[Game.initialState]
    no sprev: State | sprev.next = Game.initialState
    -- Every transition is a valid move
    all s: State | some Game.next[s] implies {
      some row, col: Int, p: Player | {
        move[s, row, col, p, Game.next[s]] 
      }
      or
      doNothing[s, Game.next[s]]      
    } 
}
```

As it stands, this fix solves the _overconstraint_ problem of never seeing an early win, but introduces a new _underconstraint_ problem: we don't want `doNothing` transitions to happen just anywhere!

Here's how I like to fix it:

```alloy
gameOver[s: State] {
  some p: Player | winner[s, p]
}
```

Why a new predicate? Because I want to use different predicates to represent different concepts. 

When should a `doNothing` transition be possible? _When the game is over!_

```alloy
pred doNothing[pre: State, post: State] {
    gameOver[pre] -- guard of the transition
    pre.board = post.board -- effect of the transition
}
```

If we wanted to, we could add a `not gameOver[pre]` to the `move` predicate, enforcing that nobody can move at all after someone has won.

## Do The Rules Allow Cheating?

Let's ask Forge whether a `cheating` state is possible under the rules. 

```alloy
run {
  wellformed
  traces
  some bad: State | cheating[bad]
} for exactly 10 State for {next is linear}
```

This should work---assuming we don't drop the `is linear` annotation. Without it, nothing says that every state must be in the trace, and so Forge could produce an instance with an "unused" cheating state.

## Checking Conjectures

When I was very small, I thought that moving in the middle of the board would guarantee a win at Tic-Tac-Toe. Now I know that isn't true. But could I have used Forge to check my conjecture (if I'd taken 1710 at that point in life)?

<details>
<summary>Think, then Click!</summary>
Here's how I did it:    
    
```alloy
run {
  wellformed
  traces
  -- "let" just lets us locally define an expression
  --  good for clarity in the model!
  -- here we say that X first moved in the middle
  let second = Trace.next[Trace.initialState] |
    second.board[1][1] = X
  -- ...but X didn't win
  all s: State | not winner[s, X]
} for exactly 10 State for {next is linear}
```    
    
</details>


## Will This Always Work?

Let's say you're checking properties for a real system. A distributed-systems algorithm, maybe, or a new processor. Even a more complex version of Tic-Tac-Toe! 

Next time, we'll talk about the problems with traces, which turn out to be  **central challenges in software and hardware verification**. 



