# 31: Modeling Errors, CEGIS

###### tags: `Tag(sp22)`

## Logistics

* Remember we have upcoming guest lectures! You can see them all on this [calendar](https://calendar.google.com/calendar/embed?src=c_npj8brm6vkp1bjj2747tajk2i8%40group.calendar.google.com&ctz=America%2FNew_York). 

## Learning from My Mistake 

When I wrote the model for Case Study 2, it was really an adaptation of a [larger, more complex model](http://cs.brown.edu/~tbn/publications/ssdnk-fest21-forge.pdf) that I wrote together with some former 1710 students. The version we adapted used a lot of Racket scripting to produce the Needham-Schroeder part of the model, and so I tried to flatten that down into a concrete Forge file instead.

Some of you noticed an error introduced along the way. If you commented out the `attack` predicate in the final run command, the result was **still** unsatisfiable. This is a major signal that the model is overconstrained! 

### Lesson 1: Testing

When I initially wrote the N-S predicate, I quantified the timeslots like this:

```alloy
some disj t0: Timeslot, t1: Timeslot-(t0.^next), t2: Timeslot-(t1.^next) | {
```

rather than this:

```
some disj t0: Timeslot, t1: Timeslot-(t0.^~next), t2: Timeslot-(t1.^~next) | {
```

The difference is one of ordering: in the original, `t1` has to come _before_ `t0` (rendering the protocol predicate unsatisfiable when connected with other predicates, like `wellformed`). I fixed the bug in the original protocol predicate, wrote tests to confirm that, and then _forgot to fix the bug in the predicate for the modified protocol_. And since I didn't add tests for the modified protocol in the same way as for the original, this error slipped in undetected. E.g., I wrote:

```alloy
  canExecuteNSSuccessfully: {
    wellformed 
    full_exec_ns
    success    
  } 
  for 6 Timeslot for optimize is sat
```

but not:

```alloy
  canExecuteNSSuccessfully: {
    wellformed 
    full_exec_ns_modified
    success    
  } 
  for 6 Timeslot for optimize is sat
```

### Lesson 2: A New Underconstraint


After this fix, the model allowed runs where the secret and the identity in the first message were sent via separate encrypted messages. This allows an attacker to subtly replace the Alice identity with their own:

![](https://i.imgur.com/6XUFmyQ.png)

Why is this allowed? Because I'd written:

```alloy
(r.resp_n1 + r.resp_n2 + r.resp_b) = t1.data.plaintext 
```

and the `.plaintext` join works the same across multiple ciphertexts in `t1.data`. The fix was to add `one t1.data` (and analogous constraints to every other multi-datum timestep in the protocol).

### Lesson 3: Avoiding Spurious "Attacks"

But we still got counterexamples in the final run!

![](https://i.imgur.com/qDDelA3.png)

This shows Alice opening a session with the attacker, and the attacker opening a session with Bob using the same original secret.

* A: "hello Eve, I want to begin a NS session with you using S0"
* E: "hello Bob, I want to begin a NS session with you using S0"
* B: "hello Eve, acknowledging S0. I'm Bob and here's my half of S1"
* E: "hello Alice, acknowledging S0. I'm Eve and here's my half of S1"
* E: "hello Bob, acknowledging your S1. Let's talk!"
* A: "hello Eve, acknowledging your S1. Let's talk!" (edited) 

Nobody is fooled about identity. Alice believes she's talking with Eve. Bob believes he's talking with Eve. Even though the secrets are the same. So our `attack` predicate was underconstrained: we also needed to introduce a notion of the participants being confused about who is who.

### Summary

Kudos to the group that found this. I'm surprised more didn't, to be honest. Had this been found earlier, I'd very likely have made detecting it part of the rubric. (But I haven't added it.)

You should never assume a model is correct just because someone else has written some tests for it. Assumptions like that could cause you a great deal of trouble. We explicitly prompted you to consider whether you trusted the model in the previous case study; this one is no different.

## CounterExample Guided Inductive Synthesis (CEGIS)


Consider modeling [Kruskal](https://en.wikipedia.org/wiki/Kruskal%27s_algorithm) or [Prim–Jarník's](https://en.wikipedia.org/wiki/Prim%27s_algorithm) approach to finding a minimum spanning tree on a weighted graph. 

I wrote a rough model of Prim's algorithm over winter break, intending to turn it into a lecture. It never appeared in that setting, so I didn't polish it. But here it is:

```alloy
#lang forge

/*
Prim's algorithm in Forge
  Tim 2020, revised Nov 2021
*/

-------------------------------------------------------------
-- Always have a specific weighted directed graph in the background
-------------------------------------------------------------

sig Node {
    edges: set Node -> Int
}

pred wellformedgraph {
    all n, m: Node | lone edges[n][m] -- no double-edges
    all n, m: Node | some edges[n][m] implies sum[edges[n][m]] >= 0 -- no negative weights
    all n, m: Node | n.edges[m] = m.edges[n] -- symmetric
    no iden & edges.Int -- no self-loops
}

pred difflengthedges {
    -- Find a graph where all the edges are different lengths
    all n1, m1, n2, m2: Node | 
      ((n1 != n2 or m1 != m2) and some n1.edges[m1]) 
      implies 
      n1.edges[m1] != n2.edges[m2]                                                                                      
}

-------------------------------------------------------------
-- Prim-Jarnik's algorithm
-------------------------------------------------------------

-- State sig for Prim's algorithm
sig Prim {
    pnodes: set Node,
    ptree: set Node->Node
}

pred prim_init[s: Prim] {
    -- Initialize to contain an arbitrary node
    some n: Node | s.pnodes = n
    no s.ptree
}

pred extendPrim[pre, post: Prim] {
    -- Find the set of as-yet-unreached nodes 
    let candidatesWithWeights = ((Node-pre.pnodes) -> Int) & pre.pnodes.edges |
    -- Find the cheapest cost among all candidates
    let minWeight = min[candidatesWithWeights[Node]] |
    -- Find the candidates who share that cheapest cost
    let minWeightCandidates = candidatesWithWeights.minWeight |
        some m, n: Node | { 
            m in pre.pnodes
            n in minWeightCandidates
            m->n->minWeight in edges -- probably a more efficient way to do this    
            post.pnodes = pre.pnodes + n -- prevents >1 node added at a time ("some" is safe)
            post.ptree = pre.ptree + (m -> n) + (n -> m)
        }
}

pred pnoneleft[s: Prim] {
  -- note we ASSUME symmetry in the tree
  all disj n1, n2: Node | n1 in n2.^(s.ptree)
}


-----------------------------------------------
-- Run!
-----------------------------------------------

one sig PrimTrace {
    -- ASSUME {pnext is linear} will be given
    pnext: set Prim -> Prim
}

pred primTrace {
    -- modulo linear-ordering enforced at bounds level
    all p: Prim | some p.(PrimTrace.pnext) => extendPrim[p, p.(PrimTrace.pnext)]
    some initial: Prim | prim_init[initial] -- inefficient
}

pred runPrimComplete {
    wellformedgraph
    primTrace
    some p: Prim | pnoneleft[p] -- complete
}
run runPrimComplete for 5 Node, 5 Prim, 5 Int for {pnext is linear}

-------------------------------------------------------------
-- Validation
-------------------------------------------------------------

inst wikipedia {
  Node = `A + `B + `C + `D
  edges = `A->`B->2 + `A->`D->1 + `B->`D->2 + `C->`D->3
}
inst wikipedia_Prim {
  Node = `A + `B + `C + `D
  edges = `A->`B->2 + `A->`D->1 + `B->`D->2 + `C->`D->3
  pnext is linear
}


test expect {    
    {wellformedgraph difflengthedges} for 5 Node, 1 Prim, 5 Int is sat
    {runPrimComplete} for wikipedia_Prim is sat
}
```

### Verifying the Algorithm (Up To Bounds)

If we want to verify the correctness of this algorithm, using this model, we face a problem. What does it mean to find a _minimum spanning tree_ for an undirected, weighted graph $G = (V,E,w)$? It must be a set of edges $T$, such that:

* $T \subseteq E$;
* $T$ forms a tree;
* $T$ spans $V$ (i.e., $V$ contains at least one edge connected to every vertex in $V$); and
* for all other sets of edges $T_2$, if $T_2$ satisfies the previous 3 criteria, then the total weight of $T_2$ must be no less than the total weight of $T$ (i.e., $T$ is a _minimal_ weight spanning tree).

Checking the final criterion requires higher-order universal quantification. We'd need to write something like this:

```alloy
some t: set Node->Node |
  spanningTree[t]
  all t2: set Node->Node | 
    spanningTree[t2] implies weight[t2] >= weight[t]
```

Forge can eliminate the outer `some` quantifier via Skolemization: turn it into a new relation to solve for. But it can't do that for the inner `all` quantifier. How many possible edge sets are there? If there are 5 possible `Node` objects, then there are 25 possible edges between those objects, and thus $2^25 = 33554432$ possible edge sets. While, technically, Forge probably could produce a big `and` formula with 33 million children, this approach doesn't scale. So Forge won't even try.

We need a different, more structured way of attacking this problem.

### An Alternative Formula

Suppose that, instead of the above shape, we had something like this, with respect to a fixed edge set `t`:

```alloy
  some t2: set Node->Node | 
    spanningTree[t2] and weight[t2] < weight[t]
```

That is, suppose we had a prospective candidate solution `t`, and we want to search for _better solution_. This is fine: Forge can handle higher-order `some`. So we can use Forge to check a candidate solution.

### The Idea

This suggests an iterative approach. Find a candidate spanning tree---any spanning tree. Then try to find something better. And again. Until nothing better can be found. 

Since Forge is a Racket library, you can use this technique to check (e.g.) Kruskal's algorithm with a loop in Racket. It's a bit less straightforward, since you need to break out of the Forge language itself, and because this use of Forge isn't yet documented well, you'd probably need to ask questions if you needed this technique for your project. 

Note though, that since Z3py is a Python library, you can use this technique in Z3 as well. 

### More Complicated Learning

This technique is pretty specialized, though. It relies on:
* having a metric for _goodness_ (here, total edge weight); and
* a well-defined and easily checkable precondition for candidacy (here, the notion of being a spanning tree). 

Not all higher-order universal constraints exhibit these nice properties, and others which aren't higher-order can still benefit from this idea. 

Here's a classical example from formal methods: program synthesis. Suppose we were trying to [synthesize a program](http://www.csl.sri.com/users/tiwari/papers/pldi2011-bitvector.pdf) that takes a machine integer as input, and outputs the number of `1` bits in that number. We might express the goal roughly as:

```alloy
some p: program |  
  all i: Int | 
    p[i] = countBitsInInteger[i]  
```

We might proceed as follows:
* Generate a candidate program, any candidate program. 
* Check it by seeing if `some i: Int | p[i] != countBitsInInteger[i]` is satisfiable. 
    * If no, we've found a good program.
    * If yes, there's an integer `i` that the current program doesn't work for. instantiate the formula `p[i] = countBitsInInteger[i]` with the concrete value, add it to our constraints, and repeat.

More sophisticated versions of this idea will try to infer root causes for failure (rather than just learning, essentially, "...yes, but make it work for `i`, too."

This broad technique is called CounterExample Guided Inductive Synthesis (or CEGIS). It and related ideas are used heavily in synthesis tools. Similar ideas are also used inside SMT solvers to help eliminate universal quantifiers.


