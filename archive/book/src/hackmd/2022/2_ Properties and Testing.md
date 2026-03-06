# 2: Properties and Testing

###### tags: `Tag(sp22)`

Welcome back! If you're attending remotely, I hope that our Discord setup is working well for you. If not, let us know! 

The first assignment goes out today: it's a homework, in Python. If you're not familiar with Python, you should check out our optional Python lab. The homework uses a library called Hypothesis, which we'll see some of in lecture today.

## Cheapest Paths

Consider the problem of finding cheapest paths in a weighted graph. There are quite a few algorithms you might use: Dijkstra, Bellman-Ford, even a plain breadth-first search for an unweighted graph. You might have implemented one of these for another class! 

The problem statement seems simple: take a graph $GRAPH$ and two vertex names $V1$ and $V2$ as input. Produce the cheapest path from $V1$ to $V2$ in $GRAPH$. But it turns out that this problem hides a lurking issue.

Find the cheapest path from vertex $G$ to vertex $E$ on the graph below.

![](https://i.imgur.com/CT7MSgl.jpg)

<details>
<summary>Think, then click!</summary>
The path is G to A to B to E.    
    
Great! We have the answer. Now we can go and add a test case for with that graph as input and (G, A, B, E) as the output. 
    
Wait -- you found a different path? G to D to B to E?
    
And another path? G to H to F to E?
</details>

If we add a traditional test case corresponding to a _one_ of the correct answers, our test suite will falsely raise alarms for correct implementations that happen to find different answers. In short, we'll be over-fitting our tests to @italic{one specific implementation}: ours. But there's a fix. Maybe instead of writing:

`shortest(GRAPH, G, E) == [(G, A), (A, B), (B, E)]`

we write:

```
shortest(GRAPH, G, E) == [(G, A), (A, B), (B, E)] or
shortest(GRAPH, G, E) == [(G, D), (D, B), (B, E)] or
shortest(GRAPH, G, E) == [(G, H), (H, F), (F, E)]
```

What's wrong with the "big or" strategy? Can you think of a graph where it'd be unwise to try to do this?

<details>
    <summary>Think, then click!</summary>

There are at least two problems. First, we might have missed some possible solutions, which is quite easy to do; the first time Tim was preparing these notes, he missed the third path above, and students pointed it out in class. Second, there might be an unmanageable number of equally correct solutions. (The most pathological case Tim could think of was a graph with all possible edges present, all of which have weight zero).
    
</details>



This problem -- multiple correct answers -- occurs all over Computer Science, if you know where to look. Most graph problems exhibit it. Worse, so do most optimization problems. Unique solutions are convenient, but the universe isn't built for our convenience. 

What's the solution? If _test cases_ won't work, is there an alternative? (Hint: instead of defining correctness bottom-up, by small test cases, think top-down: can we say what it __means__ for an implementation to be correct, at a high level?)

<details>
<summary>Think, then click!</summary>
In the cheapest-path case, we can notice that the costs of all cheapest paths are the same. This enables us to write:

`cost(cheapest(GRAPH, G, E)) = 11`

    which is now robust against multiple implementations of `cheapest`.
    
</details>


This might be something you were taught to do when implementing cheapest-path algorithms, or it might be something you did on your own, unconsciously. We're not going to stop there, however.

Notice that we just did something subtle and interesting. Even if there are a billion cheapest paths between two vertices in the input graph, they all have that same, minimal length. Like the hint above hinted at, our testing strategy has just evolved past naming _specific_ output values to checking broader _properties_ of output values.

Similarly, we can move past specific inputs and write a function `is_valid` that takes an arbitrary `input, output` pair and returns true if and only if the output is a valid solution for the input. Just pipe in a bunch of inputs, and the function will try them all. You can apply this strategy to most any problem, in any programming language. (For your homework this week, you'll be using Python.)

Let's be more careful, though. Is there something _else_ that `cheapest` needs to guarantee for that input, beyond finding a path with the same cost as our solution?

<details>
<summary>Think, then click!</summary>
We also need to confirm that the path returned by `cheapest` is indeed a path in the graph! This is a _separate_ idea, even though, depending on how the paths are returned, computing its cost might involve walking the graph. 
</details>



In fact, there are still more things we should check. Here's a sketch of an `is_valid` function for cheapest path:

```
isValid : input: (graph, vertex, vertex), output: list(vertex) -> bool
  returns true IFF:
    (1) cost(output) is cost(trustedImplementation(output))
    (2) every vertex in output is in input's graph
    (3) every step in output is an edge in input
    ...
}
```

This style of testing is called Property-Based Testing (PBT). When we're using a trusted implementation, or some other artifact that helps us evaluate the output, it will sometimes be called Model-Based Testing (MBT).

Hopefully there are a few questions, though.

**Question:** Can we really trust the "trusted" implementation?}

No, not completely. But often, questions of correctness are really about the transfer of confidence: my old, slow implementation has worked for a couple of years now, and it's probably mostly right. I don't trust my new, optimized implementation at all: maybe it uses an obscure data structure, or a language I'm not familiar with, or maybe I don't even have access to the source code at all. 

And anyway, often we don't need recourse to any trusted model; we can just phrase the properties directly. 

**Exercise:** What if we don't have a trusted implementation?

You can use this approach whenever you can write a function that checks the correctness of a given output. It doesn't need to use an existing implementation (it's just easier to talk about that way). In the next example we won't use a trusted implementation at all!

**Question:** Where do the inputs come from?

Great question! Some we will manually create based on our own cleverness and understanding of the problem. Others, we'll generate randomly.

Random inputs are used for many purposes in software engineering: "fuzz testing", for instance, creates vast quantities of random inputs in an attempt to find crashes and other serious errors. We'll use that same idea here, except that our notion of correctness is usually a bit more nuanced.

Concretely:

![](https://i.imgur.com/gCGDK6m.jpg)


It's important to note that some creativity is still involved here: you need to come up with an `is_valid` function (the "property"), and you'll almost always want to create some hand-crafted inputs (don't trust a random generator to find the subtle corner cases you already know about!) The strength of this approach lies in its resilience against problems with multiple correct answers, and in its ability to _mine for bugs while you sleep_. Did your random testing find a bug? Fix it, and then add that input to your list of regression tests. Rinse, repeat.

If we were still thinking in terms of traditional test cases, this would make no sense: where would the outputs come from? Instead, we've created a testing system where concrete outputs don't matter (or at least don't need to be provided by us).

## Hypothesis

There are PBT libraries for most every popular language. For your homework, you'll be using a library for Python called Hypothesis. I want to spend the rest of class stepping you through using the library. Let's test a function in Python itself: the `median` function in the `statistics` library. What are some important properties of `median`?

Now let's use Hypothesis to test at least one of those properties. We'll start with this template:

```python
from hypothesis import given, settings
from hypothesis.strategies import integers, lists
from statistics import median

@given(lists(integers()))
@settings(max_examples=500)
def test_python_median(l):    
    pass

if __name__ == "__main__":
    test_python_median()

```

After some back and forth, we might end up somewhere like this:

```python
from hypothesis import given, settings
from hypothesis.strategies import integers, lists
from statistics import median
from itertools import product

@given(lists(integers(), min_size=1))
@settings(max_examples=500)
def test_python_median(l):
    if len(l) % 2 == 1:
        assert median(l) in l
    else:
        assert any(e1 in l and e2 in l for e1,e2 in product(l, repeat=2))
    # Is this enough? :-)

if __name__ == "__main__":
    test_python_median()

```

There's more to do, but hopefully this gives you a reasonably nice starting point.



## Exercise

Today's exercise will be shared on EdStem, and we don't expect you to finish it during class. Finish it anytime before Monday.