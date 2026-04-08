# CEGIS and Synthesis

<!-- Note for next year: see board layout in lecture capture. 
     This was likely more effective than trying to do this in Forge as the notes suggest.
 -->

## CounterExample Guided Inductive Synthesis (CEGIS)

!!! warning "Pseudocode"
    Many of the Forge expressions shown in this section will be demonstrative only, and won't actually run. You'll see why as we progress, but be warned!


Consider modeling [Kruskal's](https://en.wikipedia.org/wiki/Kruskal%27s_algorithm) or [Prim–Jarník's](https://en.wikipedia.org/wiki/Prim%27s_algorithm) approach to finding a minimum spanning tree on a weighted graph. In principle, we should be able to use solvers like Forge or Z3 to reason about these algorithms. There are a few questions we might want to ask about MSTs in general, and not all of them involve the algorithm. For example, we could tell the solver to:

* (A) Find a minimal spanning tree for a graph, independent of any algorithm model.
* (B) Find a run of Prim's algorithm.
* (C) Find a counter-example to correctness for Prim's algorithm (i.e., falsify "Prim's always produces a minimal spanning tree").
* (D) Find a valid MST that Prim's algorithm cannot produce.

These questions may seem similar, but they have very different implications for a solver.


## Sketching a Model

I'm going to use Forge in this example, although we could also use Z3. Forge just happens to be what I had already built the model in! 

How might we start? We'd probably have the usual `sig Node` with a field `edges: pfunc Node -> Int` to model the weighted edges. Then we would write some predicates like:

* `wellformedgraph` (a well-formedness predicate to force the graphs to be weighted and directed);
* `isSpanningTree[t]` (a domain predicate describing the conditions for `t` to be a spanning tree); and
* `runPrimComplete` (a predicate that produces a complete execution of Prim's algorithm on the underlying graph).

## Question 1: Does Prim's Only Find _Minimal_ Trees?

We've set up this kind of analysis before. We'll just create a helper relation and then say:

```forge
one sig Helper { t2: set Node -> Node -> Int }
run {
  runPrimComplete    
  isSpanningTree[t2] // `isSpanningTree` doesn't need any quantifiers.
  weight[t2] < weight[lastState.t] // lastState representing the Prim's model trace
}
```

Notice that we didn't need any universal quantification to talk about the counterexample. Instead, we could just say "Prim's found some MST. Try to find a cheaper MST". 

## Question 2: Finding an arbitrary MST

Intuitively, this version might seem even easier. There's no algorithm involved, after all. But there is one other key difference. What is it?

??? note "Think, then click."
  The previous question _already had a specific spanning tree_, the one that the Prim's model produced. It then used that as a reference and tried to find a lower-cost spanning tree. Here, we don't have that reference: we're looking for a tree to start with. 

What does it mean to find a _minimum spanning tree_ for an undirected, weighted graph $G = (V,E,w)$? It must be a set of edges $T$, such that:

* $T \subseteq E$;
* $T$ forms a tree;
* $T$ spans $V$ (i.e., $T$ contains at least one edge connected to every vertex in $V$); and
* for all other sets of edges $T_2$, if $T_2$ satisfies the previous 3 criteria, then the total weight of $T_2$ must be no less than the total weight of $T$ (i.e., $T$ is a _minimal weight_ spanning tree).

Checking the final criterion requires higher-order universal quantification. We'd need to write something like this (don't try it!):

```forge
some t: set Node->Node |
  isSpanningTree[t]
  all t2: set Node->Node | 
    isSpanningTree[t2] implies weight[t2] >= weight[t]
```

This is in contrast to the shape in the previous question. Instead of `some t, t2` it's `some t, all t2`. Forge can eliminate the outer `some` quantifier via Skolemization: turn it into a new relation to solve for. But it can't do that for the inner `all` quantifier. How many possible edge sets are there? If there are 5 possible `Node` objects, then there are 25 possible edges between those objects, and thus $2^{25} = 33554432$ possible edge sets.  

The exponent will vary depending on the modeling goals. If you can exclude all self-loops, for example, it will be $20$. Technically, Forge probably could produce a big `and` formula with 33 million children, but this approach doesn't scale. So the solver engine won't even try: it will stop running if given such a constraint.

!!! warning "We can't avoid this problem by making a `Tree` sig."
  If we try this and don't have an enormous bound on `Tree`, Forge is free to find instances with far fewer trees than exist. This is a hard problem. It's not easily solved in Z3 either.

We need a different way to attack this problem.

### An Alternative Formula

Let's be inspired by the difference between these two questions. Suppose that, instead of the above shape, we had a specific edge set `t` handed to us, with the claim that `t` was a minimal spanning tree. Well, we could try to falsify `t`'s minimality&mdash;that's what we did in the first question.

```forge
  // ... definition of t is given to us ...

  // Search for a counter-example to `t` being a MST
  one sig Helper { t2: set Node -> Node -> Int }    
  run { 
    isSpanningTree[t2]
    weight[t2] < weight[t]
  }
```

### Learning by Example

The fact that Forge can verify a _potential candidate_ MST suggests an iterative approach. We'll start by finding a spanning tree. It can be any spanning tree. Call its weight $k$. Then try to find something better, a spanning tree with length less than $k$. 
  * If we do find something better, we can add a constraint that says to only find candidates of weight $k-1$ or less, and then continue. (We could use the counterexample itself as the new candidate. But in general, this won't always work for this general kind of problem, so we'll ignore the option.)
  * If we don't find something better, the candidate is actually a MST and we can stop. 

Since Forge is a Racket library, you can use this technique via loop in Racket. And Z3py is a Python library, so you can use this technique in Z3 as well. If you need to backtrack (usually you don't, with this technique), use the `pop` and `push` functions in Z3py.

## The General Case: More Complicated Learning

The above technique is pretty specialized. It relies on:

* having a metric for _goodness_ (here, total edge weight) that the solver can express; and
* a well-defined and easily checkable precondition for candidacy (here, the notion of being a spanning tree). 

Not all higher-order universal constraints exhibit these nice properties, and others which aren't higher-order (but still lack one or both of the above) can still benefit from this idea. Here's a classic example from formal methods: program synthesis. 

Let's synthesize a program that takes an integer input and returns a boolean that's true if and only if the input is even. We can express programs as syntax trees or as ordered statements; both approaches usually work in Forge and Z3. 

```forge
// I'm ignoring a lot of detail about what a Program looks like.
some p: Program |  
  all i: Int | 
    p.returnsTrue[i] iff remainder[i,2] == 0
```

This is a toy example. Technically, it even works in Forge without modification, since the `Int` sig is finite. But let's use it to motivate the technique. 

We might proceed as follows. Initialize a set of constraints `C` that is initially empty. Then:
  * Generate a _candidate_ program that satisfies `C`. (Initially this is probably a wildly bad candidate.)
  * Check the candidate by seeing if `some i: Int | not (p.returnsTrue[i] iff remainder[i,2] == 0)` is satisfiable. 
    * If no, we've found a good program.
    * If yes, there's an integer `i` that the current program doesn't work for. Instantiate the formula `p.returnsTrue[i] iff remainder[i,2] == 0` with the concrete value, add it to our constraints, and repeat. E.g., if the candidate fails on the input `100`, we'd add `p.returnsTrue[100] iff remainder[100,2] == 0` to the constraint set. The solver might simplify this, or it might not; that doesn't matter. The point is that we've learned something that might guide the solver to do better for the next candidate. 
    
Any given iteration might not learn much. We're only preventing the exact same problem from arising again in future candidates. However: 
  * The impact is up to the solver. If it gets caught in a loop of silly minor changes ("make it work for 100", "make it work for 101", "make it work for 102", ...), we're in trouble. [There is interesting work on avoiding this situation](https://www.kroening.com/papers/cav2018-synthesis.pdf).
  * If we can find a broader root cause for the problem (e.g., "100 doesn't work because the program contains the code `if(x > 50) return false`, so avoid that if-condition) [we can learn correspondingly more powerful constraints from each counterexample](https://tnelson.github.io/publications/ndgk-seconfig19-synth.pdf).

This broad technique is called CounterExample Guided Inductive Synthesis (or CEGIS). It and related ideas turn out to also be useful inside SMT solvers, to help eliminate universal quantifiers.

!!! note "Inductive"
    If you've used proof by induction before, note that the use of "inductive" here is different! Inductive synthesis learns by example; in essence, automating [inductive reasoning](https://en.wikipedia.org/wiki/Inductive_reasoning), which is not the same thing as the inductive principle in mathematics.


For more information, I suggest skimming [this paper](http://www.csl.sri.com/users/tiwari/papers/pldi2011-bitvector.pdf) about synthesizing bit-vector manipulation programs, or [Armando Solar-Lezama's PhD thesis](https://people.csail.mit.edu/asolar/papers/thesis.pdf), where the idea was introduced.

<!-- Why isn't this made moot by AI? -->

## Why isn't traditional synthesis made useless by AI?

The "I asked ChatGPT and..." intro is overdone. But it seemed appropriate here, so I asked Claude Code (Opus 4.6, April 6, 2026) for its thoughts. I find this is sometimes useful for helping me get out of my old, tried-and-true replies. Here's what it said.

> An LLM can generate a plausible `abs(x)` implementation instantly. But it can't _guarantee_ correctness&mdash;it can only be _confident_. For a 2-line `abs`, that's fine. For a bit-manipulation trick, a concurrent protocol, or a cryptographic primitive, "confident" isn't good enough. 
> 
> The failure modes are also fundamentally different. When an LLM is wrong, it's wrong in ways that _look right_&mdash;plausible code with subtle bugs. When CEGIS fails, it either says "no program of this shape exists" or keeps searching. It doesn't silently produce something broken.
> 
> Where might LLMs _help_ CEGIS? The hard part of CEGIS is often defining the program sketch---the template of operations and wiring. An LLM can propose a reasonable sketch, and then CEGIS can fill it in with guarantees. There's active research on using neural models to guide the synthesis search or propose candidates that a solver then verifies.
> 
> The punchline: LLMs are like a very well-read colleague who can suggest code quickly but might be wrong. CEGIS is like a slower colleague who checks every case before answering. You want both. The solver's guarantee is what makes formal methods _formal_&mdash;and that's not something statistical generation can replace, only augment.

I mostly agree, although I trimmed the response for brevity.

Next: we'll compare the effectiveness of CEGIS vs. `ForAll` in Z3. 

<!-- ## But does CEGIS really make a difference? 

I built [a more complete Python example](./z3_cegis_demo.py) of (basic) program synthesis, and a [test harness](./z3_cegis_vs_forall.py) that compares CEGIS against a plain `ForAll` in Z3. For both, the code compares bounded and unbounded checks. 

!!! warning "This isn't statistically sound."
  I only ran the comparison once, so there might be cache-warming effects, transient slowdowns, garbage collection, etc. I used Claude Code to prototype the comparison, which sped up building
  it. But Claude can't run the actual experiments any faster! 
  
  I do think that the general trends are informative, though. 

Here are the results. What do you notice?
 -->
