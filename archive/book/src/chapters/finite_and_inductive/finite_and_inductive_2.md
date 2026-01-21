# 2023.8: Finite Traces: Problems With Traces 


~~~admonish note title="CSCI 1710"
Good job on Intro to Modeling! Your next homework will be released today. It's about two things:
* exploring the design space of physical keys; and 
* pooling knowledge to hack them, with a little help from Forge. 

After that homework, your curiosity modeling assignment will begin! Think of this like a miniature final project: you'll use Forge to model something you're interested in, on a relatively small scale. We like this to be a partner project if possible, so it's worth finding partners and thinking about ideas now. If you don't know anyone in the class, we'll provide some help. 
~~~

Today, we'll focus on:
* testing with examples and assertions; 
* some of the limitations of full-trace verification; and  
* trying another approach to verification that doesn't require generating full traces.

## Reminder about Examples

Where an `assert` or `run` is about checking satisfiability or unsatisfiability of some set of constraints, an `example` is about whether a _specific_ instance satisfies a given predicate. This style of test can be extremely useful for checking that (e.g.) small helper predicates do what you expect.

Why use `example` at all? A couple of reasons:
* It is often much more convenient (once you get past the odd syntax) than adding `one sig`s or `some` quantification for every object in the instance, provided you're trying to describe an _instance_ rather than a property that defines a set of them---which becomes a better option as models become more complex.
* Because of how it's compiled, an `example` can sometimes run faster than a constraint-based equivalent. 

You may be wondering whether there's a way to leverage that same speedup in a `run` command. Yes, there is! But for now, let's get used to the syntax just for writing examples. Here are some, well, examples:

```alloy
pred someXTurn {some s: State | XTurn[s]}
example emptyBoardXturn is {someXTurn} for {
  State = `State0
  no `State0.board
}
```

Here, we've said that there is one state in the instance, and its `board` field has no entries. We could have also just written `no board`, and it would have worked the same.

```alloy
-- You need to define all the sigs that you'll use values from
pred someOTurn {some b: Board | OTurn[b]}
example xMiddleOturn is {someOTurn} for {
  Board = `Board0
  Player = `X0 + `O0
  X = `X0
  O = `O0
  `Board0.board =  (1, 1) -> `X0
}
```

What about assertions, though? You can think of assertions as _generalizing_ examples. I could have written something like this:

```alloy
pred someXTurn {some b:Board | xturn[b]}
pred emptySingleBoard {
  one b: Board | true
  all b: Board, r,c: Int | no b.board[r][c]
}
assert emptySingleBoard is sufficient for someXTurn  
```

That's pretty coarse-grained, though. So let's write it in a better way:

```alloy
pred emptyBoard[b: Board] { all r, c: Int | no b.board[r][c] }
assert all b: Board | emptyBoard[b] is sufficient for xturn[b]
```

Notice how, by adding variables to the assertion, we're able to write less-verbose assertions and re-use our predicates better. 

~~~admonish tip title="But if examples are faster, why use assertions?"
First, examples aren't _always_ faster. There are also some models we'll write later where `example` isn't supported. And, of course, as the model becomes more complex, the example becomes longer and longer as you try to define the value of all fields.

But there's a more important reason: assertions can express _properties_. Because they can state arbitrary constraints, there's an analogy to property-based testing: where `example`s are like traditional unit tests, `assert`ions are like the checker predicates you wrote in Hypothesis. 

So there's a role for both of them.
~~~

## Traces: Good and Bad

When we stopped last time, we'd finished our model of tic-tac-toe. We could generate a full game of up to 10 board states, and reason about what was possible in any game. 

This works great for tic-tac-toe, and also in many other real verification settings. But there's a huge problem ahead. Think about verifying properties about a more complex system---one that didn't always stop after at most 9 steps. If we want to confirm that some bad condition can never be reached, _how long a trace do we need to check?_

<details>
<summary>Think, then click!</summary>

What's the longest (simple--i.e., no cycles) path in the transition system? That's the trace length we'd need. 
</details>

That's potentially a lot of states in a trace. Hundreds, thousands, billions, ... So is this entire approach doomed from the start? 

Note two things:
* Often there _are_ "shallow" bugs that can be encountered in only a few steps. In something like a protocol or algorithm, scaling to traces of length 10 or 20 can still find real bugs and increase confidence in correctness. 
* There's more than one way to verify. This wasn't the only technique we used to check properties of tic-tac-toe; let's look deeper at something we saw awhile back.

## Proving Preservation Inductively

Let's turn to a programming problem. Suppose that we've just been asked to write the `add` method for a linked list class in Java. The code involves a `start` reference to the first node in the list, and every node has a `next` reference (which may be null). 

Here's what we hope is a _property of linked lists_: **the last node of a non-empty list always has `null` as its value for `next`**. 

How can we prove that our `add` method preserves this property, _without_ generating traces of ever-increasing length? There's no limit to how long the list might get, and so the length of the longest path in the transition system is infinite: 0 nodes, 1 node, 2 nodes, 3 nodes,...

This might not be immediately obvious. After all, it's not as simple as asking Forge to run `all s: State | last.next = none`. (Why not?)

<details>
<summary>Think, then click!</summary>

Because that would just be asking Forge to find us instances full of good states. Really, we want a sort of higher-level `all`, something that says: "for all **runs of the system**, it's impossible for the run to contain a bad linked-list state.

</details>

This simple example illustrates a **central challenge in software and hardware verification**. Given a discrete-event model of a system, how can we check whether all reachable states satisfy some property? In your other courses, you might have heard properties like this called _invariants_.

One way to solve the problem _without_ the limitation of bounded-length traces goes something like this:
* Step 1: Ask Forge whether any starting states are bad states. If not, then at least we know that executions with no moves obey our invariant. (It's not much, but it's a start---and it's easy for Forge to check.)
* Step 2: Ask Forge whether it's possible, in any good state, to transition to a bad state. 
 
Consider what it means if both checks pass. We'd know that runs of length $0$ cannot involve a bad state. And since we know that good states can't transition to bad states, runs of length $1$ can't involve bad states either. And for the same reason, runs of length $2$ can't involve bad states, nor games of length $3$, and so on.

### How do we write this in Forge?

Not just Forge, but any other solver-based tool, including those used in industry! 

Modeling linked lists in Forge is very doable, but more complicated than I'd like to try to do in 10 minutes of class. So let's do this with the tic-tac-toe model for today. A `balanced` state is a good state.
 
This assertion checks for counterexamples to the first component: are there any bad states that are also starting states?

```alloy
assert all b: Board | initial[b] is sufficient for balanced[b]
  for 1 Board, 3 Int
```

Notice that we didn't _need_ to use the `next is linear` annotation, because we're not asking for traces at all. We've also limited our scope to exactly 1 Board. We also don't need 4 integer bits; 3 suffices. This should be quite efficient. It should also pass, because the empty board isn't unbalanced.

Now we can ask: are there any transitions from a good state to a bad state? Again, we only need 2 boards for this to make sense.

```alloy
pred moveFromBalanced[pre: Board, row, col: Int, p: Player, post: board] {
  balanced[pre]
  move[pre, row, col, p, post]
}
assert all pre, post: Board, row, col: Int, p: Player | 
  moveFromBalanced[pre, row, col, p, post] is sufficient for balanced[post]
    for 2 Board, 3 Int
```

If both of these pass, we've just shown that bad states are impossible to reach via valid moves of the system. Does this technique always work? We'll find out next time.

### Aside: Performance 

That second step is still pretty slow on my laptop: around 10 or 11 seconds to yield `UNSAT`. Can we give the solver any help? Hint: **is the set of possible values for `pre` bigger than it really needs to be?**

<details>
<summary>Think, then click!</summary>
    
If we assume the `pre` board is well-formed, we'll exclude transitions involving invalid boards. There are still a lot of these, even at `3 Int`, since row and column indexes will range from `-4` to `3` (inclusive).
    
But is it really _safe_ to assert `wellformed[pre]`? Good question! Is there a way we could check?
    
</details>





