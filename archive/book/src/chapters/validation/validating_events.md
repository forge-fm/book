# Validating Models

As we start modeling more complex systems, models become more complex. The more complex the model is, the more important it is to test the model carefully. Just like in software testing, however, you can never be 100% sure that you have tested everything. Instead, you proceed using your experience and following some methodology. 

Let's get some practice with this. Before we start modifying our locking algorithm model, we should think carefully---both about testing, but also about how the model reflects the real world. 

## Principle 1: Are you testing the _model_, or the _system_? 

When you write a test, it's important to know whether you're actually writing it to validate the model (i.e., check whether the model accurately reflects the system you're modeling) or to confirm some property you expect of the system (via a hopefully-good model). The difference is sometimes subtle, but important.

Here's an example. Back when we modeled [recursive descent on binary-search trees](../bst/descent.md), we wrote a test like this:

```
assert {some s: SearchState | {descendLeft[s] and descendRight[s]}} is unsat for 7 Node 
```

Is this testing the model, or testing the system?

<details>
<summary>Think, then click!</summary>

This is a test of the _model_. We're checking that these two transition predicates we wrote can't execute at the same time. If this wasn't true, we wouldn't be faithfully modeling the recursive descent, because it would mean that sometimes, the two branches of the algorithm's `if` conditional would execute in parallel. 

</details>

We then wrote a check like this:

```
pred bs_correct {
    all n: Node | {
        n.key = SearchState.target => 
          eventually SearchState.current = n }}
assert {binary_search_tree_v1 and searchTrace} 
  is sufficient for bs_correct for 5 Node
```

What is this testing?

<details>
<summary>Think, then click!</summary>

This is checking that, assuming our model is correct, the _system_ gives us a property that we care about. When it passes, we gain knowledge about binary search trees&mdash;not so much about our model of them. 

Of course, if it _failed_ we'd learn that our model was wrong, but only because we know that BSTs work! And if it passes, it's still possible that the model is wrong. This is why, in practice, we test the model. For example, if `searchTrace` turned out to be unsatisfiable, that would make this property check pass for the wrong reasons. So we'll test:

```
assert {searchTrace} is sat for 5 Node
```

</details>

## Principle 2: Test both Inclusion and Exclusion 

Predicates are akin to boolean-valued functions. If I write a test like this:

```
assert {some s: SearchState | descendLeft[s]} is sat for 5 Node
```

it is testing that some state can take the `descendLeft` transition. We call this a _test of inclusion_ because it checks for something being included in what a predicate accepts. But there's no guarantee yet that `descendLeft` doesn't just accept everything! So we also write _tests of exclusion_, which investigate what the predicate does not accept:

```
assert {some s: SearchState | {descendLeft[s] and descendRight[s]}} is unsat for 7 Node 
```

Whenever you write an `is necessary` or `is sufficient` assertion, it always is a test of _exclusion_. Why is that?

<details>
<summary>Think, then click!</summary>

Because `assert A is sufficient for B` means that it should be impossible to find a way to satisfy `A` but not satisfy `B`. That is, we can always rewrite the assertion as:

```
assert {A and not B} is unsat
```

</details>

The direction of implication (i.e., whether we use `is necessary` or `is sufficient`) has no bearing on whether the test is for inclusion or exclusion! These two are simply _always_ tests of exclusion, just like `is unsat`.

## Takeaways 

It's very easy to fool ourselves when modeling. When we're writing tests for a piece of software, there are two major threats to consider: 
* It's possible that the _software_ is has bugs in it. We hope to discover this via testing.
* It's also possible that _our tests_ are wrong [or overfit](../properties/pbt.md).

But in the modeling context, there are even more ways that our intuition could be off. E.g.:
* It's possible that _the system_ we're modeling has bugs in it. We hope to discover this via modeling, even if we're not working directly with an implementation.
* It's possible that _our model_ has bugs in it, and thus can't be relied upon to help us understand the system. 
* It's also possible that _our tests_ are wrong... 

Add to this the fact that we are unlikely to be able to model all aspects of a system to their full depth. We can model a binary-tree descent or a locking algorithm, but that's no guarantee that a specific implementation will be correct. This is especially true [when the published algorithm is imprecise or underspecified](https://www.pamelazave.com/chord-ccr.pdf), leading to incorrect implementations.

Modeling is powerful. But it's not a cure-all, and its benefits don't come for free. 

~~~admonish tip title="Be clear."
I like to clearly label my testing file to indicate where in the 2-by-2 grid an example, check or assertion lies: model vs. system, inclusion vs. exclusion. Often I'll even use separate files for the system vs. model distinction! 
~~~
