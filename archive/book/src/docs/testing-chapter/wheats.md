# What is a Wheat?

Included in most Forge assignments are solution file(s) for each part of the assignment.
These are referred to as _wheats_, and have the `.wheat` file extension.
These _wheats_ allow you to check your understanding of the problem using tests. As long as you can
express your question about the assignment as a test, you can receive an authoritative answer from the wheat! (For more on wheats, learning goals, and critiquing wheats, see [these lecture notes](https://hackmd.io/@lfs/SJDRo3Qpj) from February, 2023.)

To run tests in your test file (e.g. `stacks.test.frg`) using the wheat solution, follow these steps:

- Replace `open` statements to your implementation file (ex. `stacks.frg`) with the associated wheat.
  For example, you may replace `open "stacks.frg"` with `open "stacks.wheat"`. _Be careful not to open both files at the same time._
- Run your tests file as you would any other Forge file. All associated tests will be run against the _wheat_ instead of your implementation.

_Wheats_ only implement top level predicates of a project. Tests that deal with the specific internals of _your_ implementation
will not be able to be run against the wheat.

# Test Writing Strategies

**We recommend the following recipe for writing tests**. While we have found these very helpful, you do not *have* to follow these strategies.

## Strategy 1

1. Write example behaviors that you believe the wheat would allow and non-examples that the wheat would rule out in terms of Forge’s example syntax.
   1. Run your test file to check your examples and non-examples against the wheat. Revise any that fail the check.
2. Study your examples and develop properties that are **necessary** for the wheat to hold. For each property:
   1. Add examples to the test suite for this necessary property, to make sure the property works as you intend.
   1. Using `assert necessary`, check that your property is really necessary for the wheat.
   1. If the property is not necessary for the wheat, add tests to your test-suite to figure out why.
3. Now test that the conjunction of your necessary properties is **sufficient** for the wheat.
   1. If this test succeeds, you are done. This conjunction reflects all the characteristics of a correct solution.
   1. If this test fails, Forge will provide you with counter-example(s) illustrating scenarios where all your necessary properties are true, but the wheat is not.
   1. Write some of these counter examples as non-examples of the wheat. Return to step 2.

## Strategy 2

For each predicate `p` surfaced by the wheat:

1. Write behaviors that p would allow and behaviors that the p would rule out in terms of either Forge’s example syntax or sufficient properties of the wheat. 
    1. Run your test file to check these tests against the wheat. Revise any that fail the check.
2. Study these tests and develop properties that are necessary for p to hold. For each *necessary* property (`n`):
    1. Add tests (examples or sufficient properties) of `n` to make sure the property works as you intend.
    2. Using `assert necessary`, check that `n` is really necessary for p.
    3. If `n` is necessary for p, add tests to your test-suite to figure out why.
3. Now test that the conjunction of your necessary properties is **sufficient** for the wheat.
   1. If this test succeeds, you are done. This conjunction reflects all the characteristics of a correct solution.
   1. If this test fails, Forge will provide you with counter-example(s) illustrating scenarios where all your necessary properties are true, but the wheat is not.
   1. Write some of these counter examples as non-examples of the wheat. Return to step 2.


## Walking through Strategy 1

Let's put Strategy 1 into action by  figuring out how to implement a predicate describing a
list.
```
sig Node { 
    next: lone Node
}

pred isList {
   ...
}
```

 **Step 1**: Write some examples and counter-examples of this predicate, and make sure they pass the wheat.

```

test suite for isList {
    example line is {isList} for
    {
        Node = `Node0 + `Node1 + `Node2 
        edges = `Node0->`Node1 + `Node1->`Node2 
    }

    example twoLists is {not isList} for
    {
        Node = `Node0 + `Node1 + `Node2 + `Node3
        edges = `Node0->`Node1 + `Node2->`Node3 
    }
 }
```

**Step 2**: The two examples above pass the wheat. We now look at them, trying to see if they describe a necessary property of `isList`.
While there are many such properties, one that immediately comes to mind is: "The entire list must be connected".

As a result, you may write the following property:

```
pred connected {
(one a : Node | 
    all b : Node | 
        a != b => reachable[b, a, next]) 
}
```

We should substantiate this property with some tests. Notice that these are tests for `connected`, not `isList`.
```
test suite for connected {
    example loop is {atMostOneParent} for
    {
        Node = `Node0 + `Node1
        next = `Node0->`Node1 +  `Node1->`Node0
        
    }
    // More tests

}
```

Now, we can assert that this is indeed a necessary property of the wheat.

```
assert connected is necessary for isList
```

If this fails the wheat, add more examples to the test suite for `connected` to figure out why.
Perhaps the property needs to be revised. In this case the test **will fail**. Connected requires a list
to be non-empty. We would have to revise the predicate to allow for empty lists.
Once you have fixed `connected`, repeat **Step 2** to come up with more necessary properties.


** Step 3**: Say we now have 2 properties necessary for `isList`: `noSelfLoops` and `connected`.
Write a predicate to check the conjunction of these 2 properties and check if it is
sufficient for the wheat. **If this test succeeds, your necessary properties characterize the wheat. You can
use these properties to write your solution!**


```
pred allNecessary {
    noSelfLoops
    connected
}

assert allNecessary is sufficient for isList
```

In this case, however, these 2 properties are not sufficient for `isList`. Upon running this test
against the wheat, Forge will provide you with an instance where 
all your necessary properties are true, but the wheat is not.

Write this out as an counter-example (i.e., a non-example of the wheat), and return to step 2.


