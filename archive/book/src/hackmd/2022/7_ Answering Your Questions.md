# 7: Answering Your Questions 

###### tags: `Tag(sp22)`

Now that the main "whirlwind tour" of Forge is done, I'll try to devote part of every lecture from now on to answering questions from prior exercises, EdStem, etc. 

## Nulls

Suppose I added this predicate to our `run` command:

```alloy
pred myIdea {
    all row1, col1, row2, col2: Int | 
        (row1 != row2 or col1 != col2) implies
            Trace.initialState.board[row1][col1] != 
            Trace.initialState.board[row2][col2]
}
```

For context, recall that we had defined a `Trace` sig earlier:

```alloy
one sig Trace {
  initialState: one State,
  nextState: pfunc State
}
```

What do you think would happen?

<details>
<summary>Think (or try it in Forge) then click!</summary>
It's very likely this predicate would be unsatisfiable, given the constraints on the initial state. Why? 
    
Because null equals itself. In Forge, null is called `none`. We can check this:
    
```alloy
    test expect {
        nullity: {none != none} is unsat
    } 
```    
    
Thus, when you're writing constraints like the above, you need to watch out for `none`: _every_ cell in the initial board is equal to _every_ other cell!
</details>

## Some Versus Some

The keyword `some` is used in 2 different ways in Forge:
* it's a _quantifier_, as in `some s: State, some p: Player | winner[s, p]`; and
* it's a _constraint operator_, as in `some Traces.initialState.board[1][1]`. 

This is a bit unfortunate. We kept the same syntax as Alloy on this for backward compatability, but I'm tempted to change it for next year, and use something for the constraint that better reflects its nature, like `notnull`, or remove it entirely.

## Implies vs. Such That

You can read `some row : Int | ...` as "There exists some integer `row` such that ...". The transliteration isn't quite as nice for `all`; it's better to read `all row : Int | ...` as "In all integer `row`s, it holds that ...". 

If you want to _further restrict_ the values used in an `all`, you'd use `implies`. But if you want to _add additional requirements_ for a `some`, you'd use `and`.  Here are 2 examples:
* "Everybody who has a `parent1` doesn't also have that person as their `parent2`": `all p: Person | some p.parent1 implies p.parent1 != p.parent2`.
* "There exists someone who has a `parent1` and a `spouse`": `some p: Person | some p.parent1 and some p.spouse`.

**Technical aside:** The type designation on the variable can be interpreted as having a character similar to these add-ons: `and` (for `some`) and `implies` (for `all`). E.g., "there exists some `row` such that `row` is an integer and ...", or "In all `row`s, if `row` is an integer, it holds that...".

## There Exists `some` Object vs. Some Instance

Forge searches for instances that satisfy the constraints you give it. Every `run` in Forge is about _satisfiability_; answering the question "Does there exist an instance, such that...". 

But, crucially, **you cannot talk about the existence, or non-existence, of an _instance_ in Forge constraints**. Every set of constraints you write is meant to filter the enormous instance set described by the numeric bounds you give Forge.

You can use this to check properties by flipping the problem around: ask Forge to find _counter-examples_. This isn't the same as negating _the model_. You want the model constraints to hold in any counterexample, or else it is spurious! Instead, ask for instances that satisfy the model and satisfy the _negation_ of your property. We're going to write one of these checks today.

## Tests In Forge

Since all Forge ever does is check satisfiability, a test is a satisfiability check---just like a `run` statement. The difference is that a test doesn't open a visualizer, or wait for you to say to move on. You can write suites of tests wrapped in the `test expect` operator, and name individual tests before their constraint block. E.g., something that's a really good idea to include with a trace-based model is a test that there are any traces whatsoever:

```alloy
test expect {
    tracesExist: {wellformed and traces} is sat
}
```

You can use tests to check your model for over- and under-constraint (as the above) but also to passively do property checking about the system you're modeling if you don't want to open a visualizer for each property.

**Technical Aside:** By the way, Forge _currently_ spawns a new solver process for every `run` or test, which means some inefficiency when you have many tests in your model. This is something I want to fix (it also makes our continuous-integration suite really slow), but didn't get to during break. **(This was changed for Spring 2023)**

## One Versus Some

The `one` quantifier is for saying "there exists a UNIQUE ...". As a result, there are hidden constraints embedded into its use. `one x: A | myPred[x]` really means, roughly, `some x: A | myPred[x] and all x2: A | not myPred[x]`. This means that interleaving `one` with other quantifiers can be subtle; I try not to use it in class for that reason.

...but it is so convenient sometimes...

## Testing Predicate Equivalence

Checking whether or not two predicates are _equivalent_ is the core of quite a few Forge applications---and a great debugging technique sometimes. 

How do you do it? Like this (note one test is correct, one incorrect):

```alloy
pred myPred1 {
    some i1, i2: Int | i1 = i2
}
pred myPred2 {
    not all i2, i1: Int | i1 != i2
}
test expect {
    -- correct: "no counterexample exists"
    p1eqp2_A: {
        not (myPred1 iff myPred2)        
    } is unsat
    -- incorrect: "it's possible to satisfy what i think always holds"
    p1eqp2_B: {
        myPred1 iff myPred2
    } is sat

}
```

If you get an instance where the two predicates aren't equivalent, you can use the Sterling evaluator to find out **why**. Try different subexpressions, discover which is producing an unexpected result!

## Back To Tic-Tac-Toe: Ending Games

When we stopped last time, we'd written this `run` command:

```alloy
run {
  wellformed
  traces
} for exactly 10 State for {next is linear}
```

**Reminder:** Without a `run`, a `test`, or a similar _command_, running a Forge model will do nothing. 

From this `run` command, Forge will find _traces_ of the system (here, games of Tic-Tac-Toe) represented as a linear sequence of exactly 10 `State` objects.

Do you have any worries about the way this is set up?

<details>
<summary>Think, then click!</summary>
Are all Tic-Tac-Toe games 10 states long? 
    
Well, _maybe_; it depends on how we define a game. If we want a game to stop as soon as nobody can win, our `exactly 10 State` bound is going to prevent us from finding games that are won before the final cell of the board is filled.    
</details>

Let's add the following guard constraint to the `move` transition, which forces games to end as soon as somebody wins.

```alloy
all p: Player | not winner[pre, p]
```

Now we've got problems. Normally we could fix the issue by getting rid of the `exactly`. Unfortunately, there's a hidden snag: when we tell Forge in this way that that `next` is linear, it automatically makes the bound exact. 

This behavior, which I admit is bizarre at first, exists for two reasons:
* historical reasons: we inherit `is linear` from Alloy, which uses somewhat different syntax to mean the same thing; and
* performance reasons: since the `is linear` annotation is almost always used for trace-generation, and trace-generation solving time grows (in the worst case) exponentially in the length of the trace, we will almost always want to reduce unnecessary uncertainty. Forcing the trace length to always be the same reduces the load on the solver, and makes trace-generation somewhat more efficient.

But now we need to work around that constraint. Any ideas? Hint: do we need to have _only one_ kind of transition in our system?
 
<details>
<summary>Think, then click!</summary>
No. A common way to allow trace length to vary is by adding a "do nothing" transition. (In the literature, this is called a _stutter transition_.) 
    
The trick is in how to add it without also allowing a "game" to consist of nobody doing anything. To do that requires some more careful modeling.

</details>

## Looking Ahead

More on this next time! 

