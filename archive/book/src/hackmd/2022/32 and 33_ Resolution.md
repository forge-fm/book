# 32 and 33: Resolution

###### tags: `Tag(sp22)`

## Logistics

* Remember we have upcoming guest lectures! You can see them all on this [calendar](https://calendar.google.com/calendar/embed?src=c_npj8brm6vkp1bjj2747tajk2i8%40group.calendar.google.com&ctz=America%2FNew_York). 

This document contains a two-class sequence on resolution proofs and how they relate to boolean solvers. This material will be directly useful in your 2nd SAT homework. 

## Context: Proofs vs. Instances

Almost all of our work in 1710 so far has focused on _satisfiability_: given constraints, how can they be satisfied? Our conversations have a character that puts instances first---how are they related, how can they be changed, how can a partial instance be completed, etc. In the field of logic, this is called a _model-theoretic_ view.

But there's a second perspective, one that focuses on necessity, deduction, and contradiction---on justifying unsatisfiability with _proof_. Today we'll start exploring the proof-theoretic side of 1710. But we'll do so in a way that's immediately applicable to what we already know. In particular, by the time we're done with this week, you'll understand a basic version of how a modern SAT solver can return a _proof_ of unsatisfiability. This proof can be processed to produce cores like those Forge exposes via experimental `solver`, `core_minimization`, etc. options.

We'll start simple, from CNF and unit propagation, and move on from there.

## A Chain Rule For CNF

Suppose I know two things:
* it's raining today; and
* if it's raining today, we can't hold class outside.
 
I might right this more mathematically as the set of known facts: $\{r, r \implies \neg c\}$, where $r$ means "rain" and $c$ means "class outside". I'm using $\implies$ for "implies" and $\neg$ for "not" to stick to the usual math notation for these sorts of things.

Given this knowledge base, can we infer anything new? Yes! We know that if it's raining, we can't hold class outside. But we know it's raining, and therefore we can conclude class needs to be indoors. This intuition is embodied formally as a logical _rule of inference_ called _modus ponens_:

<center>
<p>

$\frac{A, A \implies B}{B}$
</p>                
</center>

The horizontal bar in this notation divides the inputs to the rule from the outputs. For _any_ $A$ and $B$, if we know $A$, and we know $A \implies B$, we can use modus ponens to deduce $B$.

I like to think of rules of inference as little enzymes that operate on formula syntax. Modus ponens recognizes a specific pattern of syntax in our knowledge base, _rewrites_ that pattern into something new. And for rules like this, we can check them for validity using a truth table:

| $A$ | $B$ | $A \implies B$ | 
| ----| --- | -------------- |
|  0  |  0  |       1        |
|  0  |  1  |       1        |
|  1  |  0  |       0        |
|  1  |  1  |       1        |

In any world where both $A$ and $A \implies B$ is true, $B$ must be true.

**Important:** Remember that in classical logic (our setting for most of 1710), $A \implies B$ is equivalent to $\neg A \vee B$---either $A$ is false (and thus no obligation is incurred), _or_ $B$ is true (satisfying the obligation whether or not it exists).

### Beyond Modus Ponens

But suppose we don't have something as straightforward as $\{r, r \implies \neg c\}$ to work with. What if we have:
* if it's raining today, we can't hold class outside; and
* if Tim is carrying an umbrella, then it's raining today.

That is, we have a pair of implications: $\{u \implies r, r \implies \neg c\}$. We cannot conclude that it's raining from this knowledge base, but we can still conclude something: that _if_ Tim is carrying an umbrella, _then_ we can't hold class outside. We've learned something new, but it remains contingent: $u \implies \neg c$.

We can think of this as a generalization of modus ponens, which lets us chain together implications to generate new contingencies:

<center>
<p>

$\frac{A \implies B, B \implies C}{A \implies C}$
</p>                
</center>

Like before, we can check it with a truth table. This time, there are 8 rows:

| $A$ | $B$ | $C$ | $A \implies B$ | $B \implies C$ | $A \implies C$ | 
| ----| --- | --- | -------------- | -------------- | -------------- |
|  0  |  0  |  0  |       1        |        1       |       1        |
|  0  |  0  |  1  |       1        |        1       |       1        |
|  0  |  1  |  0  |       1        |        0       |       1        |
|  0  |  1  |  1  |       1        |        1       |       1        |
|  1  |  0  |  0  |       0        |        1       |       0        |
|  1  |  0  |  1  |       0        |        1       |       1        |
|  1  |  1  |  0  |       1        |        0       |       0        |
|  1  |  1  |  1  |       1        |        1       |       1        |


## Propositional Resolution

The _resolution rule_ is a generalization of what we just discovered. Here's the idea: because we can view an "or" as an implication, we should be able to apply this idea of chaining implications to _clauses_.

First, let's agree on how to phrase clauses of more than 2 elements as implications. Suppose we have a clause $(l_1 \vee l_2 \vee l_3)$. Recall that:
* a clause is a big "or" of literals;
* a literal is either a variable or its negation; and 
* $\vee$ is just another way of writing "or".

We might write $(l_1 \vee l_2 \vee l_3)$ as an implication in a number of ways, e.g.:
* $(l_1 \vee l_2 \vee l_3) \equiv (\neg l_1 \implies (l_2 \vee l_3))$
* $(l_1 \vee l_2 \vee l_3) \equiv (\neg l_2 \implies (l_1 \vee l_3))$
* $(l_1 \vee l_2 \vee l_3) \equiv (\neg l_3 \implies (l_1 \vee l_2))$
* $(l_1 \vee l_2 \vee l_3) \equiv ((\neg l_1 \wedge \neg l_2) \implies l_3)$
* $(l_1 \vee l_2 \vee l_3) \equiv ((\neg l_1 \wedge \neg l_3) \implies l_2)$  
* $(l_1 \vee l_2 \vee l_3) \equiv ((\neg l_2 \wedge \neg l_3) \implies l_1)$

So if we have a large clause, there may be more ways of phrasing it as an implication than we'd want to write down. Instead, let's make this new rule something that works on clauses directly. 

How would we recognize that two clauses can be combined like the above? Well, if we see something like these two clauses: 
* $(l_1 \vee l_2)$; and 
* $(\neg l_1 \vee l_3)$
then, if we wanted to, we could rewrite them as:
* $(\neg l_2 \implies l_1)$; and 
* $(l_1 \implies l_3)$
and then apply the above rule to get:
* $(\neg l_2 \implies l_3)$.
We could then rewrite the implication back into a clause:
* $(l_2 \vee l_3)$.

Notice what's happened. The two opposite literals have cancelled out, leaving us with the union of everything else in the two clauses.

<center>
<p>

$\frac{(A \vee B), (\neg B \vee C)}{(A \vee C)}$
</p>                
</center>

This is called the _binary propositional resolution rule_. It generalizes to something like this (where I've labeled literals in the two clauses with a superscript to tell them apart):

<center>
<p>

$\frac{(l^1_1 \vee l^1_2 \vee ... \vee l^1_n), (\neg l_1 \vee l^2_1 \vee ... \vee l^2_m)}{(l^1_2 \vee l^1_n \vee l^2_1 \vee ... \vee l^2_m)}$
</p>                
</center>

This rule is a very powerful one. In particular, since unit propagation is a basic version of resolution (exercise: think about why!) our SAT solvers will be able to use resolution to _prove_ to us why an input CNF is unsatisfiable.

### Resolution Proofs

What is a proof? For our purposes, it's a tree where
* each leaf is a clause in some input CNF; and 
* each internal node is an application of the resolution rule to two other nodes.

Here's an example resolution proof that shows the combination of 4 clauses is contradictory:

![](https://i.imgur.com/fEBkPm7.png)

**Vitally, this tree is not a paragraph of text written on a sheet of paper. This is a tree---a data structure, a computational object, which we can process and manipulate in a program.**


Resolution is _sound_, and so any tree whose root produces the empty clause (falsehood) and whose leaves are a subset of the input, comprises a proof of unsatisfiability for the input CNF.

Resolution is _refutation complete_: for any unsatisfiable CNF, there exists a resolution proof of its unsatisfiability.

### Getting Some Practice

Here's a CNF:

```
(-1, 2, 3)
(1)
(-2, 4)
(-3, 5)
(-4, -2)
(-5, -3)
```

Can you prove that there's a contradiction here?

<details>
<summary>Prove, then click!</summary>

Let's just start applying the rule and generating everything we can...    
    
![](https://i.imgur.com/o9sNUzk.png)

Wow, this is a lot of work! Notice two things:
* we're sort of going to end up with the same kind of 4-clause contradiction pattern as in the prior example; 
* it would be nice to have a way to guide generation of the proof, rather than just generating _every clause we can_. An early form of DPLL did just that; DPLL added the branching and backtracking. So, maybe there's a way to use the structure of DPLL to guide proof generation...
    
</details>
<br/>

Notice that one of the resolution steps you used was, effectively, a unit propagation. Unit propagation (into a clause were the unit is negated) is a very basic kind of resolution---used when one clause is empty.

<center>
<p>

$\frac{(A), (\neg A \vee ...)}{(...)}$
</p>                
</center>

How about the other aspect of unit propagation---the removal of clauses entirely when they're subsumed by others? 

<details>
<summary>Think, then click!</summary>
    
Interestingly, it doesn't need to. That's an optimization for the solver; here, a proof is free to disregard clauses it doesn't need to use.
    
</details>



## Learning From Conflicts

Let's return to that CNF from before:

```
(-1, 2, 3)
(1)
(-2, 4)
(-3, 5)
(-4, -2)
(-5, -3)
```

Instead of trying to build a _proof_, let's look at what your DPLL implementations might do when given this input. I'm going to try to sketch that here---note that your own implementation may be slightly different. (That doesn't necessarily make it wrong!) **Open up your implementation as you read, and follow along**.

* Called on: `[(-1, 2, 3), (1), (-2, 4), (-3, 5), (-4, -2), (-5, -3)]`
* Unit-propagate `(1)` into `(-1, 2, 3)` to get `(2, 3)`
* There's no more unit-propagation to do, so we need to branch. We know the value of `1`, so let's branch on `2` and try `True` first.
* Called on: `[(2), (2, 3), (1), (-2, 4), (-3, 5), (-4, -2), (-5, -3)]`
* Unit-propagate `(2)` into `(-2, 4)` to get `(4)`.
* Remove `(2, 3)`, as it is subsumed by `(2)`.
* Unit-propagate `(4)` into `(-4, -2)` to get `(-2)`.
* Remove `(-2, 4)`, as it is subsumed by `(4)`.
* Unit-propagate `(-2)` into `(2)` to get the empty clause. 

Upon deriving the empty clause, we've found a contradiction. _Some part_ of the assumptions we've made so far (here, only that `2` is `True`) contradicts the input CNF.

If we wanted to, we could learn a new clause that disjoins (applies `or` to) all the assumptions made to reach this point. But there might be many assumptions in general, so it would be good to do some sort of fast analysis: learning a new clause with 5 literals is a lot better than learning a new clause with 20 literals!

Here's the idea: we're going to use the unit-propagation steps we recorded to derive a resolution proof that the input CNF plus the assumptions lead to the empty clause. We'll then reduce that proof into a "conflict clause". This is one of the key ideas behind how modern solvers---CDCL, or Conflict Driven Clause Learning solvers---improve on DPLL. We won't talk about all the tricks that CDCL uses here, nor will you have to implement them. If you're curious for more, consider shopping CSCI 2951-O. For now, it suffices to be aware that reasoning about _why_ a conflict has been reached can be useful for performance. 

In the above case, what did we actually use to derive the empty clause? Let's work _backwards_. We'll try to produce a linear proof where the leaves are input clauses or assumptions, and the internal nodes are unit-propagation steps (remember that these are just a restricted kind of resolution). We ended with:

* Unit-propagate `(-2)` into `(2)` to get the empty clause. 

The `(2)` was an assumption. The `(-2)` was derived:

* Unit-propagate `(4)` into `(-4, -2)` to get `(-2)`.

The `(-4, -2)` was an input clause. The `(4)` was derived:

* Unit-propagate `(2)` into `(-2, 4)` to get `(4)`.

The `(-2, 4)` was an input clause. The `(2)` was an assumption.

Now we're done; we have a proof:

![](https://i.imgur.com/H6iqwAf.png)

Using only those two input clauses, we know that assuming `(2)` won't be productive.

## Explaining Unsatisfiable Results 

This is promising: we have a _piece_ of the overall proof of unsatisfiability that we want. But we can't use it alone: it's got an assumption in it. Fortunately, we can again take inspiration from clause learning. We don't need to derive the empty clause, we just need to derive `(-2)`---the negation of the assumption responsible. 

Let's recursively process the (contingent) proof we generated before. We'll *remove* assumptions from the tree and recompute the result of every resolution step, resulting in a proof of something weaker that isn't contingent on any assumptions. This pseudocode won't exactly match your code, but it sketches the idea:

```
def rebuild(tree_node):
    match tree_node:
        case Input(_): return tree_node
        case ResolutionStep(Assumption(_), c2): return rebuild(c2)
        case ResolutionStep(c1, Assumption(_)): return rebuild(c1)
        case ResolutionStep(c1, c2): return resolve(rebuild(c1), rebuild(c2))
        case _: raise Exception('resolve_all {}'.format(trace))
```

If you pre-emptively avoid using assumptions in your DPLL code, this is significantly simpler, but would likely still require you to re-run resolution over the tree. 

When we run that on the above proof, we get:

![](https://i.imgur.com/oAjYL8V.png)

It turns out we didn't need the assumption `(-2)` to derive `(2)`. This makes sense, because we know that the assumption leads to a contradiction---so we'd need to have derived `(-2)` somewhere!

#### Advice

Break down these operations into small helper functions, and write test cases for each of them. Really! It's very easy for something to go wrong somewhere in the pipeline, and if your visibility into behavior is only at the level of DPLL, you'll find it much harder to debug issues. 

Remember that you can use PBT on these helpers as well. The assignment doesn't require it, but it can be helpful.

#### Takeaway

This should illustrate **the power of being able to treat proofs as just another data structure**. Resolution proofs are just trees. (Binary trees, in fact---at least for our purposes.) Because they are trees, we can manipulate them programatically. We just transformed a proof of the empty clause via assumptions into a proof of something else, without assumptions.

This is what you'll do for your homework. 

### Combining sub-proofs

Suppose you ran DPLL on the false branch `(-2)` next. Since the overall input is unsatisfiable, you'd get back a proof of `(2)` from the inputs. And, given a proof tree for `(-2)` and a proof tree for `(2)`, how could you combine them to show that the overall CNF is unsatisfiable? 

<details>
<summary>Think, then click!</summary>

Just combine them with a resolution step! If you have a tree rooted in `(2)` and another tree rooted in `(-2)`, you'd produce a new resolution step node with those trees as its children, deriving the empty clause.
</details>

### Testing Part 2

Given one of these resolution proofs of unsatisfiability for an input CNF, you can now apply PBT to your solver's `False` results.

What properties would you want to hold? (Deciding that is part of the assignment!)

## Pre-Registration!

Pre-registration is upon us! Some related courses include the following. I'll restrict myself to those about, or closely related to logic, formal methods, or programming languages, and which can count for the CSCI concentration as of the present version of the [Handbook](https://cs.brown.edu/degrees/undergrad/concentrating-in-cs/concentration-handbook/).

* CSCI 1010 (theory of computation)
* CSCI 1600 (real-time and embedded software)
* CSCI 1730 (programming languages)
* CSCI 1951X (formal proof and verification)
* PHIL 1630 (mathematical logic)
* PHIL 1880 (advanced deductive logic) 
* PHIL 1855 (modal logic)

Rob Lewis, who teaches 1951X, will be giving Friday's guest lecture. 

There are many other great courses---some of which I might argue should also count as upper-level courses for the CSCI concentration, or which are only taught in the Spring semester. For instance, PHIL 1885 covers incompleteness and would be an interesting counterpoint to a more CSCI-focused course on computability.

