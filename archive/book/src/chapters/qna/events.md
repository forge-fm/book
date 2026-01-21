# Q&A: Event Systems

**TODO: consider advanced question: correspondence??? is there one between the array version and the tree version?**



## More on Optimization: `inst` Syntax

The syntax that you use in `example`s and to say `is linear` for a field (like you saw in the [ripple-carry adder](../adder/rca.md)) is more expressive than you've seen so far. Recall that Forge has [two phases](./static.md): deliniating the allowed search space, and solving the constraints within that search space. This new syntax lets you define a _partial instance_, which affects the first phase to limit the possible instances the solver will consider.

You can even define a reusable partial instance using the `inst` command, and use it in the same place you'd use `{next is linear}` in a `run`, `assert`, etc. For example, we could pre-define the set of full adders in the [ripple-carry adder](../adder/rca.md) model, giving each an atom name:

```alloy
inst fiveBits {
  FA = `FA0 + `FA1 + `FA2 + `FA3 + `FA4 + `FA5
} 
run {rca} for exactly 1 RCA for {fiveBits}
```

Because this defines the set of `FA` atoms that must exist, it does something quite similar to just saying `for exactly 5 FA`. If we then add entries for the `RCA`'s fields, we manually accomplish what `nextAdder is linear` would as well, while simultaneously making sure the first full adder in that ordering is what we see in `RCA.firstAdder`:

```alloy
inst fiveBits {
  RCA = `RCA0 
  FA = `FA0 + `FA1 + `FA2 + `FA3 + `FA4 + `FA5
  -- Remember the back-tick mark here before atom names! 
  `RCA0.firstAdder = `FA0
  `RCA0.nextAdder = `FA0 -> `FA1 + `FA1 -> `FA2 + `FA2 -> `FA3 + 
                    `FA3 -> `FA4 + `FA4 -> `FA5
} 
run {rca} for exactly 1 RCA for {fiveBits}
```

So far this is just a long-handed way of doing what we've already done. But partial instances are far more flexible. Remember the optimization we had to do in [tic-tac-toe games](../ttt/ttt_games.md), where we reduced the bitwidth from `4` to `3`? Partial instances give us a much finer degree of control. Where `for 3 Int` still allows any integer between `-4` and `3` to be used, we can use a partial instance to _force_ well-formedness, before the solver ever sees a constraint: 

```forge 
inst ttt_indexes {
  Board = `Board0
  X = `X   O = `O
  Player = X + O
  board in Board -> (0 + 1 + 2) -> (0 + 1 + 2) -> Player
}
```

This says that any entry in any board's `board` field can only use the values `0` through `2`, inclusive. It has an impact very similar to the `wellformed` pred we wrote, but can be much more efficient. (You'll learn more about why in the next chapter.)

**Exercise**: Compare the statistical info for the original tic-tac-toe game run with and without this added partial instance information. Do you notice any changes? What do you think might be going on, here? 

<details>
<summary>Think, then click!</summary>

The statistical information is reporting runtime, but also something else: the number of "clauses" and "variables". It turns out these express how big the boolean constraint problem is before the solver gets it. Partial instances can reduce these, and thus make the problem easier for the solver. 

</details>
