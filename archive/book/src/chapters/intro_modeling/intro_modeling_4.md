# 2023.5: Intro to Modeling (Part 4, FAQ)

~~~admonish note title="(Brown CSCI 1710) Logistics"
We'll be starting in-class exercises soon. These are graded for participation, but are a significant part of your grade. 
~~~

Today we're going to answer some anticipated questions Then we'll move on to more modeling in tic-tac-toe. 

~~~admonish note title="For Brown CSCI 1710"
You might have seen on your homework that we're asking you to generate a family tree demonstrating how someone can be their own "grandparent", without also being their own "ancestor". This might, quite reasonably, sound contradictory.

One of the tricky things about modeling is that often you're trying to formalize something informal. Is it possible that one of those statements is about biology, and one is a social definition, which might be a bit more broad? 
~~~

## A Visual Sketch of How Forge Searches

There are infinitely many potential family tree instances based on the model you're working on in this week's homework. But Forge needs to work with a finite search space, which is where the bounds of a `run` come in; they limit the set of instances Forge will even consider. Constraints you write are _not yet involved_ at this point.

Once the bounded search space has been established, Forge uses the constraints you write to find satisfying instances within the bounded search space.

![](https://i.imgur.com/eQ76Hv8.png)

This is one reason why the compiler is a bit less smart than we'd like. The engine uses bounds and constraints very differently, and inferring constraints is often less efficient than inferring bounds. But the engine treats them differently, which means sometimes the distinction leaks through.

## "Nulls" in Forge

In Forge, there is a special value called `none`. It's analogous (but not exactly the same) as a `null` in languages like Java. 

Suppose I added this predicate to our `run` command in the tic-tac-toe model:

```alloy
pred myIdea {
    all row1, col1, row2, col2: Int | 
        (row1 != row2 or col1 != col2) implies
            Game.initialState.board[row1][col1] != 
            Game.initialState.board[row2][col2]
}
```

I'm trying to express that every entry in the board is different. This should easily be true about the initial board, as there are no pieces there.

For context, recall that we had defined a `Game` sig earlier:

```alloy
one sig Game {
  initialState: one State,
  nextState: pfunc State -> State
}
```

What do you think would happen?

<details>
<summary>Think (or try it in Forge) then click!</summary>

It's very likely this predicate would be unsatisfiable, given the constraints on the initial state. Why? 
    
Because `none` equals itself! We can check this:
    
```alloy
test expect {
    nullity: {none != none} is unsat
} 
```    
    
Thus, when you're writing constraints like the above, you need to watch out for `none`: the value for _every_ cell in the initial board is equal to the value for _every_ other cell!
</details>


~~~admonish tip title="Reachability and none"
The `none` value in Forge has at least one more subtlety: `none` is "reachable" from everything if you're using the built-in `reachable` helper predicate. That has an impact even if we don't use `none` explicitly. If I write something like: `reachable[p.spouse, Nim, parent1, parent2]` I'm asking whether, for some person `p`, their spouse is an ancestor of `Nim`. If `p` doesn't have a spouse, then `p.spouse` is `none`, and so this predicate would yield true for `p`.
~~~

## Some as a Quantifier Versus Some as a Multiplicity

The keyword `some` is used in 2 different ways in Forge:
* it's a _quantifier_, as in `some b: Board, p: Player | winner[s, p]`, which says that somebody has won in some board; and
* it's a _multiplicity operator_, as in `some Game.initialState.board[1][1]`, which says that that cell of the initial board is populated. 

## Implies vs. Such That

You can read `some row : Int | ...` as "There exists some integer `row` such that ...". The transliteration isn't quite as nice for `all`; it's better to read `all row : Int | ...` as "In all integer `row`s, it holds that ...". 

If you want to _further restrict_ the values used in an `all`, you'd use `implies`. But if you want to _add additional requirements_ for a `some`, you'd use `and`.  Here are 2 examples:
* **All**: "Everybody who has a `parent1` doesn't also have that person as their `parent2`": `all p: Person | some p.parent1 implies p.parent1 != p.parent2`.
* **Some**: "There exists someone who has a `parent1` and a `spouse`": `some p: Person | some p.parent1 and some p.spouse`.

**Technical aside:** The type designation on the variable can be interpreted as having a character similar to these add-ons: `and` (for `some`) and `implies` (for `all`). E.g., "there exists some `row` such that `row` is an integer and ...", or "In all `row`s, if `row` is an integer, it holds that...".

## There Exists `some` *Atom* vs. Some *Instance*

Forge searches for instances that satisfy the constraints you give it. Every `run` in Forge is about _satisfiability_; answering the question "Does there exist an instance, such that...". 

Crucially, **you cannot write a Forge constraint that quantifies over _instances_ themselves**. You can ask Forge "does there exist an instance such that...", which is pretty flexible on its own. E.g., if you want to check that something holds of _all_ instances, you can ask Forge to find counterexamples. This is how `assert ... is necessary for ...` is implemented, and how the examples from last week worked.

## One Versus Some

The `one` quantifier is for saying "there exists a UNIQUE ...". As a result, there are hidden constraints embedded into its use. `one x: A | myPred[x]` really means, roughly, `some x: A | myPred[x] and all x2: A | not myPred[x]`. This means that interleaving `one` with other quantifiers can be subtle; for that reason, we won't use it except for very simple constraints.

If you use quantifiers other than `some` and `all`, beware. They're convenient, but various issues can arise.

## Testing Predicate Equivalence

Checking whether or not two predicates are _equivalent_ is the core of quite a few Forge applications---and a great debugging technique sometimes. 

How do you do it? Like this:

```alloy
pred myPred1 {
    some i1, i2: Int | i1 = i2
}
pred myPred2 {
    not all i2, i1: Int | i1 != i2
}
assert myPred1 is necessary for myPred2
assert myPred2 is necessary for myPred1
```

If you get an instance where the two predicates aren't equivalent, you can use the Sterling evaluator to find out **why**. Try different subexpressions, discover which is producing an unexpected result! E.g., if we had written (forgetting the `not`):

```alloy
pred myPred2 {
    all i2, i1: Int | i1 != i2
}
```

One of the assertions would fail, yielding an instance in Sterling you could use the evaluator with.

#### Old Testing Syntax and a Lesson

Alternatively, using the older `test expect` syntax works too. I'm not going to use this syntax in class if I don't need to, because it's less _intentional_. But using it here lets me highlight a common conceptual issue with Forge in general.

```alloy
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

These two tests do not express the same thing! One asks Forge to find an instance where the predicates are not equivalent (this is what we want). The other asks Forge to find _an_ instance where they _are_ equivalent (this is what we're hoping holds for any instance, not just one)!

~~~admonish warning title="Use `assert`" 
We encourage using `assert` whenever possible in practice. We'll show you soon how to use `assert` with predicates that take arguments, etc. 
~~~